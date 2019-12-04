% This file calculates the # of shares to buy / sell short for the ARS strategy:
%%%INPUT%%%
% input1: trading signals from an xls sheet
% input2: params of the download prices equations
%%%EQUATIONS%%%
%calculate the # of buy and sell signals
%calculate the # of shares to buy / sell short
%%%OUTPUT%%%
% # of shares to buy / sell
% xls with # of shares to buy / sell
% emails (to folder draft)5
%%%Methods:
%1) download_prices_BBG (external)
%2) downloadVolumesBBG (external)
%3) downloadIsinBBG (external)
%4) extrapolateSgn (external)
%5) downloadVolumes5min (external)
%%%Set before running:
%1)investedVolumeRatio_threshold (in main)
%2)lagvol (in main)
%3)frequency (in main)
%4)minLongAndShort (in xls)
%%%NOTES%%%
%1) If code is broken, activate the check after volumes download
% adjust the IPO issue: the stock YJ US, listed on May 3rd, 2019
% i) has a bug on volumes (volume_mat) and restrict the start date (May
% 1st, 2019, of all the securities composing the vintage)

close all;
clear all;
clc;

%%%%%%%%%%%%
%Paths%%%%%%
%%%%%%%%%%%%

pt = path;
userId = getenv('USERNAME');
addpath(['C:\Users\' userId '\Documents\GitHub\Utilities\']);
addpath(['C:\Users\' userId '\Documents\GitHub\TradingSystems\Accessories']);
addpath(['C:\Users\' userId '\Documents\GitHub\TradingSystems\ANALYST_STRATEGY\Accessories']);

%%%%%%%%%%%%%%%%%%%%%%%
%Bloomberg params%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%

download        = 1; % download switch, 1 if plugged into BBG
dateFormat      = 'dd/MM/yyyy'; 
DataUtilities   = DataUtils(); % calls the 3x download methods

lastPrices  = [];
lastPrices  = [];
volume      = [];
investedVolumeRatio = [];

% Trading global settings:
investedVolumeRatio_threshold = 0.1; %param: set before running
holdingPeriod   = 10; % SET HOLDING PERIOD
lagvol          = 20; % SET volume BACKWARD LAG (days of trading)
basicSize       = 50000;

% volume 5min download settings:
volume_granularity  = [5, 30, 60, 120, 390]; % minutes
volume_openTime     = '15:30:00'; % market opening time 
volume_closeTime    = '22:00:00'; % market closing time
lag5min             = 3;
volume_thresholdsMultiplier = 0.1;


field_last      = 'PX_LAST';
field_open      = 'PX_OPEN';
field_volume    = 'TURNOVER'; 
field_ISIN      = 'ID_ISIN'; 
field_mktCap    = 'CUR_MKT_CAP';

currency  = 'USD';              % set currency
frequency = 'Daily';            % set frequency
adjustmentNormal   = true;      % BBG adjustment 1 
adjustmentAbnormal = true;      % BBG adjustment 2 
adjustmentSplit    = true;      % BBG adjustment

% Gather download params in a structure
downloadParams = struct();
downloadParams.field_last   = field_last;
downloadParams.field_open   = field_open;
downloadParams.volumes      = field_volume;
downloadParams.field_ISIN   = field_ISIN;
downloadParams.marketCap    = field_mktCap;
downloadParams.frequency    = frequency;
downloadParams.currency     = currency;
downloadParams.adjustmentNormal   = adjustmentNormal;
downloadParams.adjustmentAbnormal = adjustmentAbnormal;
downloadParams.adjustmentSplit    = adjustmentSplit; % Store the prices open and close

%%%%%%%%%%%%%%%%%%%%%%%
%Importing signals%%%%%
%%%%%%%%%%%%%%%%%%%%%%%

liveInputFile   = 'Signals_traded_LIVE.xlsx';
liveInputFolder = 'Input/';
allInputTable   = readtable([liveInputFolder, liveInputFile]); %transfering from xls to matlab

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  Transforming input table and prep. output %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

allDates                = datetime(allInputTable.CorrectedDate, 'Format', dateFormat);  %taking dates from the "CorrectedDate" column
allTradeDatesUnique     = unique(allDates) %returns the same values with no repetitions.
openPositionDate        = allTradeDatesUnique(end)

tradingDates = openPositionDate;

if length(allTradeDatesUnique) >= holdingPeriod
    closePositionDate   = allTradeDatesUnique(end-holdingPeriod) %changed
    tradingDates = [closePositionDate, tradingDates]; 
end

allSizes            = 100000 * allInputTable.SIZE; %adjust size (scale)

% Initialize the output table (create structure and converting to table)
recordStruct = struct();
recordStruct.TradeDate      = [];
recordStruct.Vintage        = [];
recordStruct.TickerBBG      = {};
recordStruct.Signal         = [];
recordStruct.Action         = {};
recordStruct.SharesAmount   = [];
recordStruct.Qcheck         = [];
recordStruct.LocalBroker    = []; 
recordStruct.ISIN           = {};
recordStruct.mktCap         = [];
recordStruct.mktCap_trader  = {};
recordStruct.volumeBin      = [];
recordStruct.Note   = [];
recordTradeTable = struct2table(recordStruct);

volumeBin_num       = [1:6];
volumeBin_actions   = {'on_close'     ; ...
                         'last_30_min'  ; ...
                         'last_1_hour'	; ...
                         'last_2_hours' ; ...
                         'till_close'   ; ...
                         'till_close' };
                 
volumeBinMap        = containers.Map(volumeBin_num, volumeBin_actions);    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  download data, set rules and construct output %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Loop over 2xdates;
for dateCount = 1:length(tradingDates)
  
    % Extrapolate and show the current date
    currentDate = tradingDates(dateCount);
    disp(currentDate)
        
    % Cut the portion correspoding to the current date, and extrapolate the downloading parameters (start/end date and assets) from it
    dailySignalsTable   = allInputTable(datetime(allInputTable.CorrectedDate )== currentDate, :);
    dailyAssetList      = dailySignalsTable.TickerBBG; %cell array
    howManyAssets       = length(dailyAssetList);
       
    lastTradingDate = busdate(currentDate, -1); %BUSDATE: take business days only
    startDate = lastTradingDate;
    endDate   = lastTradingDate;
    
    % add further download parameters
    downloadParams.univ         = dailyAssetList;
    downloadParams.start_date   = startDate;
    downloadParams.end_date     = endDate;

    %%%%%start downloading%%%%%% 
    
    if download == 1
        % Set the bloomberg connection 
        downloadParams.lagvol       = lagvol;
        downloadParams.connection   = blp;
        pricesParams = downloadParams;  % create ad-hoc structure for downloading "prices"
        volumeParams = downloadParams;  % create ad-hoc structure for downloading "volumes"
        volumeParams.start_date.Day = volumeParams.start_date.Day - lagvol; 
        
        % Download prices:
        [bbgLastPrices, ~]  = DataUtilities.download_prices_BBG(pricesParams);
        
        % Download mkt cap:
        bbgMarketCap        = DataUtilities.downloadMarketCapBBG(downloadParams);
        
        % Fill missing values
        bbgLastPrices(cellfun(@(x) isempty(x),bbgLastPrices)) = {[nan, nan]};
        bbgMarketCap(cellfun(@(x) isempty(x), bbgMarketCap))  = {[nan, nan]};
        
        % and put them in a matrix form
        lastPrices_mat  = cell2mat(bbgLastPrices);
        marketCap_mat   = cell2mat(bbgMarketCap);
        lastPrices      = lastPrices_mat(:, 2);
        mktCap          = marketCap_mat(:,2);

        % Download volumes and calculate its mean over the reference period (corresponds to volumeParams.start_date.Day - 120):
        bbgVolume = DataUtilities.downloadVolumesBBG(volumeParams);
        bbgVolume(cellfun(@(x) isempty(x),bbgVolume)) = {[nan,nan]};
        
        try
            bbgVolume_filled = DataUtilities.fillHistoricalSeries(bbgVolume);
        catch
            disp('')
        end
        volume_mat  = cell2mat(bbgVolume_filled(:)');
        volumes     = mean(volume_mat(:, 2:2:end))';
          
        % Download ISIN:
        ISIN = downloadISIN(DataUtils, downloadParams);

% ===============\\\CHECK\\\=========================
%       activate this check if code is broken
%       tickerToCheck = dailyAssetList(find((cell2mat(cellfun(@(x) isempty(x), bbgVolume, 'UniformOutput', false))==1)));
%         if ~isempty(tickerToCheck)
%             dateToCheck = tradingDatesUnique(dateCount);
%             disp(['Check the following date: ' datestr(dateToCheck)]);
%             disp(['Check the following tickers: ' tickerToCheck]);
%         end
% ===============\\\END OF CHECK\\\=================     

        % Download volume data at 5 mins granularity
   
        downloadParams.lag5min = 3;
        downloadParams.enddate5min = endDate;
        downloadParams.granularity = [5, 30, 60, 120, 390]; % minutes
        downloadParams.opening = '15:30:00'; % market opening time 
        downloadParams.closing = '22:00:00'; % market closing time

        volume5min     = DataUtilities.downloadVolumes5min(downloadParams);
        volume5min_avg = cellfun(@(x) min(x(:,2:end)), volume5min, 'UniformOutput', false);
        volume5MinMat  = cell2mat(volume5min_avg);
        volume_Threshold = volume_thresholdsMultiplier *  volume5MinMat ;
    
        %%%%% end downloading %%%%%% 
    
    % generate random data if BBG connection is not available;   
    elseif download == 0
        lastPrices          = randi([1 1500], howManyAssets, 1);
        volume5MinMat       = 5*10*(randi([2 5], howManyAssets, 1)) .* rand(howManyAssets, 1);
        volume5MinMat       = cumsum(real(10.^randi([1 4], howManyAssets, howManyAssets, 'like', 1))* rand(howManyAssets, length(volume_granularity)),2);
        volume_Threshold    = volume_thresholdsMultiplier * volume_5mins_Mat;
        mktCap              = 5e06 * rand(howManyAssets, 1);

        ISIN.ID_ISIN    = cell(howManyAssets, 1);
        ISIN.ID_ISIN(:) =  {'DUMMY_ISIN'};
    end
 
    % Initialize the trading record structure
    dailyRec = recordStruct;
    dailyRec.TradeDate  = dailySignalsTable.TradeDate;
    dailyRec.Vintage    = dailySignalsTable.Vintage;
    dailyRec.TickerBBG  = dailySignalsTable.TickerBBG;
    dailyRec.Signal     = dailySignalsTable.Signal;
    
    minperLeg_tmp       = unique(dailySignalsTable.minLongAndShort); %take param from "dailySignalTable", previously imported from xls
   
    % Extrapolate long, short signals and the "doWeTrade" switch
    dailySignals      = dailySignalsTable.Signal;
    [sgn, howMany, ~] = extrapolateSgn(dailySignals');
   
    doWeTradeDummy = minperLeg_tmp <= howMany.short & minperLeg_tmp  <= howMany.long
      
    howManySignals = howMany.long * sgn.long - howMany.short * sgn.short; % Create a vector with the # of securities for each asset
    investedPerLeg = 50000*dailySignalsTable.SIZE;  %adjust size (scale)
    daily_Actions  = cell(howManyAssets, 1);
    
    daily_Actions(:)        = {'LOW_LIQUIDITY'};
    daily_SharesAmount      = zeros(howManyAssets, 1);
    daily_liquidityRatio    = zeros(howManyAssets, 1);
    daily_Qcheck            = zeros(howManyAssets, 1);
    localBroker             = NaN(howManyAssets,1);
    
    if doWeTradeDummy ==1
        % For each asset compute the shares amount and the volume ratio. 
        try
            daily_SharesAmount = round(investedPerLeg./ (howManySignals'.*lastPrices));
        catch
            disp('')
        end
        
        daily_liquidityRatio = (daily_SharesAmount.*lastPrices)./volumes;
        liqudityConstraint   = daily_liquidityRatio < investedVolumeRatio_threshold; % Activate the liquidity constraint
      
        % If we trade AND we pass the liquidity constraint, switching the action label from "LOW_LIQUIDITY" to "BUY" or "SELL"
        daily_Actions(and(liqudityConstraint, dailySignals == -1)) = {'SHORT_SELL'};
        daily_Actions(and(liqudityConstraint, dailySignals == 1))  = {'BUY' };
        
        % The daily_SharesAmount is computed regardless of the liquidity constraint
        daily_SharesAmount(~liqudityConstraint) = 0;
                
    elseif doWeTradeDummy ==0
        
        % If we do not trade, the whole column of daily actions will be overwritten with "NO_TRADE" and # shares amount remains 0.
        daily_Actions(:) = {'NO_TRADE'};
        
    end
    
    % Assigning stocks to time intervals bins: 
    % "SharesVsVolume_switch" has "0" and "1" entries; for each row, if column "x_i" has a  "1", then columns on its right have all a "1". We sum columnwise;   
        %   Ex:
        %
        %      [0 0 0 1 1 1]   |--> [3]
        %      [0 1 1 1 1 1]   |--> [5]
        %      [0 0 0 0 1 1]   |--> [2]
        %      [0 0 1 1 1 1]   |--> [4]
        %
        %   We build a "1" matrix with same dimension of "SharesVsVolume_switch" and we sum columnwise; 
        %   
        %      [1 1 1 1 1 1] |--> [6]   
        %      [1 1 1 1 1 1] |--> [6]     
        %      [1 1 1 1 1 1] |--> [6]   
        %      [1 1 1 1 1 1] |--> [6]    
        %
        %   We substract the latter sum from the first sum, and we add 1, in order to obtain the first time a "1" appairs in "SharesVsVolume_switch"          
        %   
        %        [6]     [3]     [4]         
        %    1+  [6]  -  [5] =   [2] 
        %        [6]     [2]     [5]
        %        [6]     [4]     [3]
        %
    
     sharesVsVolume_switch   = daily_SharesAmount < volume_Threshold;
     volumeBin	= 1 + sum(ones(size(sharesVsVolume_switch)),2) - sum(sharesVsVolume_switch,2); 
    
     mktCap_trader   = cell(howManyAssets,1);
     mktCap_trader(find(mktCap < 1e03))                      = {'S'};
     mktCap_trader(find((1e03 <= mktCap) & (mktCap < 3e04))) = {'B'}; 
     mktCap_trader(find(mktCap >= 3e04 ))                    = {'D'}; % Trading at open only stocks with mktcap>USD30bln (increased with increased size) 
    
    % Assign further fields to the dailyRec structure and modify / create tables  
    dailyRec.SharesAmount   = daily_SharesAmount;
    dailyRec.Qcheck         = daily_Qcheck;
    dailyRec.LocalBroker    = localBroker 
    dailyRec.Action         = daily_Actions;
    dailyRec.ISIN           = ISIN.ID_ISIN;
    dailyRec.mktCap         = mktCap;
    dailyRec.mktCap_trader  = mktCap_trader;
    dailyRec.volumeBin      = volumeBin;
    dailyRec.Note   = arrayfun(@(x) volumeBinMap(x), volumeBin, 'UniformOutput', false);
    dailyRec_tmp_tb         = struct2table(dailyRec);
    recordTradeTable        = [recordTradeTable; dailyRec_tmp_tb];
    investedVolumeRatio     = [investedVolumeRatio; daily_liquidityRatio];
end

%% Prepare trading record = open positions + closing  positions

% Closing position 
closingPositionRows = find(recordTradeTable.TradeDate == closePositionDate);
signalToClose = recordTradeTable.Signal(closingPositionRows);
closingSignal = -1 * signalToClose;
actionToClose = recordTradeTable.Action(closingPositionRows);
sellToCloseRows = find( strcmp(actionToClose, 'SHORT_SELL'));
buyToCloseRows  = find( strcmp(actionToClose, 'BUY'));

% Closing actions: where there's a SELL overwrite a BUY and viceversa.
recordTradeTable.Signal(closingPositionRows) = closingSignal;
recordTradeTable.Action(sellToCloseRows) = {'BUY'};
recordTradeTable.Action(buyToCloseRows)  = {'SELL'};

tradeRecord_folderName  = 'Opening vintages';
tradeRecord_fileName    = [ 'recordTradeTable_openDate_' datestr(openPositionDate, 'yyyy-mm-dd'), '.xlsx'];
tradeRecordFilePath     = [tradeRecord_folderName, '/' tradeRecord_fileName];

recordTradeTable
TableForTrading=recordTradeTable(:,[2:10,12:13])
writetable(TableForTrading, tradeRecordFilePath)

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Creating emails for trading%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%
%AM ORC%%%
%%%%%%%%%%

recipients  = 'AM.orc@intesasanpaolo.com; ServiceDesk.Finanza.gso@intesasanpaolo.com'; 
subject     = ['Censimento'];  
body        = sprintf('Buongiorno, pls censire, grazie, D. \n\n');
 
for sgnCount = 1: size(recordTradeTable, 1)
  
  lastRec_struct = table2struct(recordTradeTable(sgnCount,:));

  tkr_tmp   = lastRec_struct.TickerBBG;
  isin_tmp  = lastRec_struct.ISIN;
  body = [body, sprintf('\t\t\t') tkr_tmp, sprintf('\t\t'), isin_tmp, sprintf('\n\n')]; 
  
end

h    = actxserver('outlook.Application');
mail = h.CreateItem('olMail');
mail.Subject    = subject;
mail.To         = recipients;
mail.BodyFormat = 'olFormatHTML';
mail.HTMLBody   = body;
mail.Save;
h.release;

%%%%%%%%%%%%%%%%%%%
%Lending 1%%%%%%%%%
%%%%%%%%%%%%%%%%%%%

recipients = 'GM.StockLending@bancaimi.com'; 
subject = ['Short'];  
body = 'Buongiorno, mi chiudete gli short in allegato? Grazie, D.'
h = actxserver('outlook.Application');
mail = h.CreateItem('olMail');
mail.Subject = subject;
mail.To = recipients;
mail.BodyFormat = 'olFormatHTML';
mail.HTMLBody = body;
mail.Save;
h.release;

%%%%%%%%%%%%%%%%%%%
%Lending 2%%%%%%%%%
%%%%%%%%%%%%%%%%%%%

recipients = 'GM.StockLending@bancaimi.com; equityCM@bancaimi.com'
subject = ['Short'];  
body = 'Buongiorno, mi prendete a prestito le azioni “SHORT_SELL” in allegato? Grazie, D.'
h = actxserver('outlook.Application');
mail = h.CreateItem('olMail');
mail.Subject = subject;
mail.To = recipients;
mail.BodyFormat = 'olFormatHTML';
mail.HTMLBody = body;
mail.Save;
h.release;

%%%%%%%%%%%%%%%%%%%
%Email for broker%%
%%%%%%%%%%%%%%%%%%%

recipients = 'lennart.pleus@berenberg.com'; 
subject = ['Trades'];  
body = 'Hi all, pls find attached the trades for today. Pls trade in accordance with the note. Best regards, D.'
h = actxserver('outlook.Application');
mail = h.CreateItem('olMail');
mail.Subject = subject;
mail.To = recipients;
mail.BodyFormat = 'olFormatHTML';
mail.HTMLBody = body;
mail.Save;
h.release;


%%
%Disposed Features

%Feat1
% Add attachments, if specified.
% if ~isempty(attachments)
% 
%     for i = 1:length(attachments)
% 
%         mail.attachments.Add(attachments{i});
% 
%     end
% 
% end

%Feat2
% Assign trader according to mktCap:
%     mktCap_trader   = cell(howManyAssets,1);
%     mktCap_trader(find(mktCap < 1e03))                      = {'S'};
%     mktCap_trader(find((1e03 <= mktCap) & (mktCap < 3e04))) = {'B'}; 
%     mktCap_trader(find(mktCap >= 3e04 ))                    = {'D'}; % Trading at open only stocks with mktcap>USD30bln (increased with increased size) 

%Feat3 
% lastRecord = dailyRec_tmp_tb  %create "lastRecord" table
% %rangeCell = computeTableRange(tblCell, distanceRow)
% %include vtc in cell array
% % Recording "vintage to close"
% vintageToClose_count = max(0, length(allTradeDatesUnique) -9)
% disp('Vintage to close');
% vtc_table = recordTradeTable(find(recordTradeTable.Vintage == vintageToClose_count), :)
% 
% % Recording "short to close"
% shortToClose_count = max(0, length(allTradeDatesUnique) -10)
% shortToClose_table=recordTradeTable(find(recordTradeTable.Vintage == shortToClose_count & recordTradeTable.Signal == -1), {'Signal', 'ISIN', 'SharesAmount','TickerBBG'})
% 
% %creating file
% lastRecord_fileName   = ['lastRecord_tradeDate_' datestr(dailyRec.TradeDate(1), 'yyyy-mm-dd'), '.xlsx']; 
% lastRecord_folderName = 'Opening vintages';
% 
% %checking directory
% if ~exist(lastRecord_folderName, 'dir')
%     mkdir(lastRecord_folderName);
% end
% 
% writetable(lastRecord, [lastRecord_folderName, '\', lastRecord_fileName]);
% recordTradeTable;  %trading infos gathered here

%masterTradeTable = join(allInputTable, recordTradeTable, 'Keys', {'TradeDate', 'Vintage', 'TickerBBG', 'Signal'});
%masterTradeTable = addvars(masterTradeTable, investedVolumeRatio, 'NewVariableNames','investedVolumeRatio');