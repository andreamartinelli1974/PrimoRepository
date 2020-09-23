%%% STYLE ATTRIBUTION FROM BC MODEL TO DASHBOARD

close all; clear all; clc;

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

%%%%%%*********** TO DO: UPDATE THE PATH IN FINAL VERSION ***********%%%%%%

addpath([dsk,'Users\' userId '\Documents\GitHub\Utilities\'], ...
        ['C:\Users\' userId '\Desktop\EFI\CODE\output\FMP\'],...
        ['X:\SalaOp\EquityPTF\Dashboard\outRiskExcel\'],...
        ['C:\Users\' userId '\Desktop\'],...
        [dsk,'Users\' userId '\Documents\GitHub\PrimoRepository\CodeForDashboard']); 
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

StyleMapPath = 'X:\SalaOp\EquityPTF\Dashboard\outRiskExcel';

%% READ THE BC MODEL TABLE WITH "ALL ASSETS" CLASSIFICATION

% disp('loading index data');
% 
% MyStyleMapFile = 'file.xlsx' %%% output from FMP
% 
% inputData = readtable(MyStyleMapFile);

% sedol to ticker conversion


%% READ THE PRTU_STATIC FILE FROM DASHBOARD

disp('loading portfolo data');
inputData = readtable('PRTU_STATIC.xlsx');

TableNames = inputData.Properties.VariableNames;
portfolioNames = TableNames;
index = find(contains(portfolioNames,'Var'));
portfolioNames(index) = [];
if size(inputData,2)+1 ~= numel(portfolioNames)*3
    error('some portfolio name was deleted');
end

% creates the table of all assets
AssetTable = [];
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
        newcol = cell(size(tmpList.tickers));
        newcol(:) = portfolioNames(i);
        tmpList.portfolio = newcol;
        tmpList.(portfolioNames{i}) = [];
        AssetTable = [AssetTable ;tmpList];
    end
end

%% get the relevant info from bbg
tic
disp('get fundamental ticker from bbg');

tickerlist = unique(AssetTable.tickers);
N = size(tickerlist,1);
uparams.fields = {'DX895'};%{'UNDERLYING_SECURITY_DES','SECURITY_TYP','SECURITY_TYP2'}; %,'DY993','DS428'};
uparams.override_fields = [];
uparams.history_start_date = today()-20;
uparams.history_end_date = today();
uparams.DataFromBBG = DataFromBBG;


for k=1:N
    uparams.ticker = tickerlist{k,1};
    uparams.granularity = 'daily';
    U = Utilities(uparams);
    U.GetBBG_StaticData;
    
    if isempty(U.Output.BBG_getdata.DX895{:})
        tickerlist{k,2} = 'N/A';
    else
        tickerlist{k,2} = strcat(U.Output.BBG_getdata.DX895{:},' Equity');
    end   
end

for i = 1:size(AssetTable,1)
    tkrIndex = find(contains(tickerlist(:,1),AssetTable.tickers{i}));
    AssetTable.FundTicker2{i} = tickerlist{tkrIndex,2};
end

toc
% MATCH THE STYLE CLASSIFICATION FOR ANY ASSET IN ANY PORTFOLIO

%% WRITE THE OUTPUT TABLE IN RELEVANT SHEET OF THE DASHBOARD
disp('writing the final table');

myfilename = fullfile(StyleMapPath,'StyleMap.xlsx');
delete(myfilename);
writetable(AssetTable,myfilename);

disp('DONE');