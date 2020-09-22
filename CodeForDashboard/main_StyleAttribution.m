close all; clear all; clc;

clear all;
close all;

toTest = 1; % 1 = reads from FMP , 0 from dashboard

DTW_window = 10; % window for DTW
Nperc = 5; % number of groups the asset must be divided.

start_date = today()-365;
end_date = today();
first_date_dtw = eomdate(today()-70); % get the last day of two previous months
min_hystory = 60;

% **************** STRUCTURE TO ACCESS BLOOMBERG DATA *********************
DataFromBBG.save2disk = false(1); %false(1); % True to save all Bloomberg calls to disk for future retrieval
DataFromBBG.folder = [cd,'\BloombergCallsData\'];
 
if DataFromBBG.save2disk
    if exist('BloombergCallsData','dir')==7
        rmdir(DataFromBBG.folder(1:end-1),'s');
    end
    mkdir(DataFromBBG.folder(1:end-1));
end

try
    % javaaddpath('C:\blp\DAPI\blpapi3.jar');
    DataFromBBG.BBG_conn = blp; % throw error when Bloomberg is not installed
    pause(2);
    while isempty(DataFromBBG.BBG_conn) % ~isconnection(DataFromBBG.BBG_conn)
        pause(2);
    end
    
    DataFromBBG.NOBBG = false(1); % True when Bloomberg is NOT available and to use previopusly saved data
    
catch ME
    % dlgTitle = 'BBG ALERT';
    % dlgQuest = 'BLOOMBER NOT AVAILABLE! Do you with to continue?';
    % answer = questdlg(dlgQuest,dlgTitle,'yes','no','no');
    % if strcmp(answer,'no')
    %     return
    % end
    if isdeployed
    RunMsg = msgbox('Connection to Bloomberg not available', ...
        'Deployed code execution');
    end
    DataFromBBG.BBG_conn = [];
    DataFromBBG.NOBBG = true(1); % if true (on machines with no BBG terminal), data are recovered from previously saved files (.save2disk option above)
end
% *************************************************************************

pt = path;
userId = getenv('USERNAME');
if strcmp(userId,'U370176') || strcmp(userId,'U093799')
    dsk = 'D:\';
else
    dsk = 'C:\';
end
addpath([dsk,'Users\' userId '\Documents\GitHub\Utilities\'], ...
    ['C:\Users\' userId '\Desktop\EFI\CODE\output\FMP\'],...
    ['X:\SalaOp\EquityPTF\Dashboard\outRiskExcel\'],...
    ['C:\Users\' userId '\Desktop\'],...
    [dsk,'Users\' userId '\Documents\GitHub\PrimoRepository\CodeForDashboard']); 

%% read the styles' equitylines
% get stoxx 600 hystory price for calendar reference
uparams.ticker = 'SXXP Index';
uparams.fields = 'PX_LAST';
uparams.granularity = 'daily';
uparams.override_fields = [];
uparams.history_start_date = start_date;
uparams.history_end_date = end_date;
uparams.DataFromBBG = DataFromBBG;

U = Utilities(uparams);
U.GetHistPrices;
stoxx_ts = U.Output.HistInfo;

% load data and calculate returns from start date to end date
disp('loading styles data');
StylesData = readtable('StyleEquityLine.xlsx');

StylesNames = StylesData.Properties.VariableNames(:,2:2:end);

for i = 1:numel(StylesNames)
    date = StylesData.(StylesData.Properties.VariableNames{2*i-1});
    date = datenum(date);
    prices = StylesData.(StylesData.Properties.VariableNames{2*i});
    [~,StilesIdx,~] = intersect(date,stoxx_ts(:,1));
    Styles.(StylesNames{i}).TimeSeries.Prices = [date(StilesIdx), prices(StilesIdx)];
    
    % calculate returns
    retParams.lag = 1;
    retParams.pct = 1;
    retParams.logret = 1;
    retParams.ExtendedLag = 3;
    % params assumed constant for now
    retParams.rolldates = [];
    retParams.last_roll = [];
    retParams.EliminateFlag = 0;
    retParams.data1 = Styles.(StylesNames{i}).TimeSeries.Prices;
    retParams.data2 = [];
    
    U = Utilities(retParams);
    U.RetCalc;
    U.Output.CleanRet;
    Styles.(StylesNames{i}).TimeSeries.Returns = U.Output.CleanRet; 
end

%% read the portfolio

if toTest
    %%% read the assets from AllStocksStyle20200731_with_tickers.xlsx 
    disp('loading portfolio data');
    inputData = readtable('AllStocksStyle20200731_with_tickers.xlsx');
    
    tickersList = strcat(inputData.ticker,' Equity');
    
    
    % tickersList = readtable('MSCI All Country.xlsx','Sheet','msci');
    % tickersList = readtable('MSCI All Country.xlsx','Sheet','Sheet2');
else
    %%% read the ptf from PRTU_STATIC.xlsx
    disp('loading portfolo data');
    inputData = readtable('PRTU_STATIC.xlsx');
    
    TableNames = inputData.Properties.VariableNames;
    portfolioNames = TableNames;
    index = find(contains(portfolioNames,'Var'));
    portfolioNames(index) = [];
    if size(inputData,2)+1 ~= numel(portfolioNames)*3
        error('some portfolio name was deleted');
    end
    % creates the list of all assets
    AssetList = [];
    for i = 1:size(portfolioNames,2)
        % reads the portfolio names and quantity from xls file
        tmpList = [];
        index = find(strcmp(TableNames, portfolioNames{i}));
        tmpList = inputData(2:end,index-1:index);
        myNames = tmpList.Properties.VariableNames;
        disp(['now processing ',myNames{2},' portfolio']);
        myNames{1} = 'tickers';
        tmpList.Properties.VariableNames = myNames;
        % remove zeros lines
        nonzero = table2array(tmpList);
        indexZero = find(strcmp(nonzero(:,1),'0'));
        tmpList(indexZero,:) = [];
        % remove lines with excel errors
        indexRef = find(contains(tmpList.tickers,'VT_ERROR:'));
        tmpList(indexRef,:) = [];
        indexRef = find(contains(tmpList.tickers,'#'));
        tmpList(indexRef,:) = [];
        if ~isempty(tmpList) % if something remains, it goes ahead
            newlist = tmpList.tickers;
            AssetList = [AssetList ;newlist];
        end
    end
    
    tickersList = unique(AssetList);
    
end

AssetTable = array2table(tickersList);
AllTickers = [];
AllIndex = [];

N = size(tickersList,1);
uparams.fields = {'UNDERLYING_SECURITY_DES','SECURITY_TYP','SECURITY_TYP2'}; %,'DY993','DS428'};
uparams.override_fields = [];
uparams.history_start_date = start_date;
uparams.history_end_date = end_date;
uparams.DataFromBBG = DataFromBBG;

disp('');
disp('get securities type');

for k=1:N
    uparams.ticker = tickersList{k,1};
    uparams.granularity = 'daily';
    U = Utilities(uparams);
    U.GetBBG_StaticData;
    AssetTable.SecType(k) = U.Output.BBG_getdata.SECURITY_TYP;
    AssetTable.SecType2(k) = U.Output.BBG_getdata.SECURITY_TYP2;
    AssetTable.Underlying(k) = U.Output.BBG_getdata.UNDERLYING_SECURITY_DES;
    %AllTickers = [AllTickers; uparams.ticker ;strcat(U.Output.BBG_getdata.DY993{:},' Equity')];
    %AllIndex = [AllIndex ; strcat(U.Output.BBG_getdata.DS428{:},' Index')];
end
%AllTickers = unique(AllTickers);
%AllIndexUnique = unique(AllIndex);

%occurrences = cellfun(@(x) sum(ismember(AllIndex,x)),AllIndexUnique,'un',0)

disp('');
disp('get securities history');
for k=1:N
    
    uparams.fields = 'PX_LAST';
    if isempty(AssetTable.Underlying{k})
        uparams.ticker = tickersList{k,1};
    else
        uparams.ticker = AssetTable.Underlying{k};
    end
    U = Utilities(uparams);
    U.GetHistPrices;
    ts = U.Output.HistInfo;
    
    Tname{k} = ['a_',regexprep(uparams.ticker,'[^a-zA-Z0-9]','_')];
    
    AllAssets.(Tname{k}).ticker = tickersList{k,1};
    AllAssets.(Tname{k}).AssetType = AssetTable.SecType2{k};
    AllAssets.(Tname{k}).TimeSeries.Prices = ts;
    
    % calculate returns
    retParams.lag = 1;
    retParams.pct = 1;
    retParams.logret = 1;
    retParams.ExtendedLag = 3;
    % params assumed constant for now
    retParams.rolldates = [];
    retParams.last_roll = [];
    retParams.EliminateFlag = 0;
    retParams.data1 = ts;
    retParams.data2 = [];
    try
    U = Utilities(retParams);
    U.RetCalc;
    U.Output.CleanRet;
    tsr = U.Output.CleanRet;
    catch AM
        disp("");
    end
    
    AllAssets.(Tname{k}).TimeSeries.Returns = tsr;
    
end

%% measuring time series distances using DTW
DistanceMtx = zeros(numel(Tname),numel(StylesNames));

disp('');
disp('measuring equityline distance');
for k=1:N
    date = AllAssets.(Tname{k}).TimeSeries.Returns(:,1);
    fd = find(date(:,1) >= first_date_dtw);
    fd = fd(1);
    Return = AllAssets.(Tname{k}).TimeSeries.Returns(fd,2);
    for i = 1:numel(StylesNames)
        date = Styles.(StylesNames{i}).TimeSeries.Returns(:,1);
        fd = find(date(:,1) >= first_date_dtw);
        fd = fd(1);
        StyleReturn = Styles.(StylesNames{i}).TimeSeries.Returns(fd,2);
        DistanceMtx(k,i) = mydtw(StyleReturn,Return,DTW_window);
    end
end

% create the table
DistanceTable = array2table(DistanceMtx);
DistanceTable.Properties.VariableNames = StylesNames;
DistanceTable.Properties.RowNames = Tname;

%find the minimum distance for any asset
[misureMin,index] = min(DistanceMtx(:,1:numel(StylesNames)),[],2,'linear');
StyleMapMtx = zeros(numel(Tname),numel(StylesNames));
StyleMapMtx(index) = 1;
StyleMapTable = array2table(StyleMapMtx);
StyleMapTable.Properties.VariableNames = strcat(StylesNames,"_Min");
StyleMapTable.Properties.RowNames = Tname;

StyleMapTable = [tickersList, StyleMapTable];

% use measure distribution to find the thresholds (5% and 95% to be in and
% to be out)

StyleMapMtx = zeros(numel(Tname),numel(StylesNames));

for i = 1:numel(StylesNames)
    Styles.(StylesNames{i}).Measure.In  = prctile(DistanceMtx(:,i),40);
    Styles.(StylesNames{i}).Measure.Out = prctile(DistanceMtx(:,i),60);
    indexIn  = find(DistanceMtx(:,i)<Styles.(StylesNames{i}).Measure.In);
    indexOut = find(DistanceMtx(:,i)>Styles.(StylesNames{i}).Measure.Out);
    StyleMapMtx(indexIn,i)  =  1;
    StyleMapMtx(indexOut,i) = -1;
end

StyleMapTable2 = array2table(StyleMapMtx);
StyleMapTable2.Properties.VariableNames = strcat(StylesNames,"_Pctl");
StyleMapTable2.Properties.RowNames = Tname;

StyleMapTable = [StyleMapTable, StyleMapTable2];

writetable(StyleMapTable,['StyleMapTable_',num2str(today()),'.xlsx']);
