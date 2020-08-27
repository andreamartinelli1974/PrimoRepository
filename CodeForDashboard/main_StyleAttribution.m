close all; clear all; clc;

clear all;
close all;

toTest = 0; % 1 = reads from FMP , 0 from dashboard

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
    [dsk,'Users\' userId '\Documents\GitHub\PrimoRepository\CodeForDashboard']); 


if toTest
    %%% read the assets from AllStocksStyle20200731_with_tickers.xlsx 
    disp('loading data');
    inputData = readtable('AllStocksStyle20200731_with_tickers.xlsx');
    
    tickersList = strcat(inputData.ticker,' Equity');
    
else
    %%% read the ptf from PRTU_STATIC.xlsx
    disp('loading data');
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

N = size(tickersList,1);
uparams.fields = {'UNDERLYING_SECURITY_DES','SECURITY_TYP','SECURITY_TYP2'};
uparams.override_fields = [];
uparams.history_start_date = today()-365;
uparams.history_end_date = today();
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
end

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
    
    Tname = ['a_',regexprep(uparams.ticker,'[^a-zA-Z0-9]','_')];
    
    AllAssets.(Tname).ticker = tickersList{k,1};
    AllAssets.(Tname).AssetType = AssetTable.SecType2{k};
    AllAssets.(Tname).TimeSeries.Prices = ts;
    
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
    
    U = Utilities(retParams);
    U.RetCalc;
    U.Output.CleanRet;
    tsr = U.Output.CleanRet;
    
    AllAssets.(Tname).TimeSeries.Returns = tsr;
    
end
    


