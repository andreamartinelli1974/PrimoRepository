close all; clear all; clc

% initial settings


userId = lower(getenv('USERNAME'));

if strcmp(userId,'u093799')
    dsk = 'D:\';
else
    dsk = 'C:\';
end

addpath([dsk,'Users\' userId '\Documents\GitHub\Utilities\']);

if strcmp(userId,'u093799')
    inputDataFolder = ['D:\Users\',userId,'\Documents\GitHub\PrimoRepository\Tbricks\SSL\'];
else
    inputDataFolder = ['D:\TBricks\'];
end


positions_eod_fileName = "TB_POSITION_EOD_20200828.txt";
futures_eod_fileName = "TB_FI_FUTURE_EOD_20200828.txt";
options_eod_fileName = "TB_FI_OPTION_EOD_20200828.txt";
mktAttributes_eod_fileName = "TB_FI_MARKET_ATTRIBUTES_EOD_20200828";
isin_eod_fileName = "TB_FI_EOD_20200828.txt";
greeks_eod_fileName = "TB_POSITION_ANALYTICS_GREEKS_EOD_20200828.txt";

mainPtfTable = [];

%% **************** STRUCTURE TO ACCESS BLOOMBERG DATA *********************
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


%% READ EOD POSITIONS 

% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 23);

% Specify range and delimiter
opts.DataLines = [3, Inf];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["CURRENCY", "INSTRUMENT_FE", "INSTRUMENTID_FE", "TBRICKS_INSTRUMENT_ID", "MFAMILY", "MGROUP", "MTYPE", "PL_KEY_FE", "PORTFOLIOID", "POSITIONID", "POSPRICE", "POSPRICE_BUY", "POSPRICE_SELL", "QUANTITY", "QUANTITY_BUY", "QUANTITY_LIVE", "QUANTITY_SELL", "REF_DATE", "TYPOLOGY", "INVESTED", "POSITION_CASHFLOW_ID", "MARKET_NAME", "MIC_JOIN_MKT_ATTR"];
opts.VariableTypes = ["string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "double", "string", "string", "double", "double", "string", "double", "datetime", "string", "double", "string", "string", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["INSTRUMENT_FE", "INSTRUMENTID_FE", "TBRICKS_INSTRUMENT_ID", "POSITIONID", "POSPRICE_BUY", "POSPRICE_SELL", "QUANTITY_LIVE", "TYPOLOGY", "POSITION_CASHFLOW_ID"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["CURRENCY", "INSTRUMENT_FE", "INSTRUMENTID_FE", "TBRICKS_INSTRUMENT_ID", "MFAMILY", "MGROUP", "MTYPE", "PL_KEY_FE", "PORTFOLIOID", "POSITIONID", "POSPRICE_BUY", "POSPRICE_SELL", "QUANTITY_LIVE", "TYPOLOGY", "POSITION_CASHFLOW_ID", "MARKET_NAME", "MIC_JOIN_MKT_ATTR"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "REF_DATE", "InputFormat", "yyyy-MM-dd");

% Import the data
Positions_EOD = readtable(inputDataFolder + positions_eod_fileName, opts);

%% READ GREEKS

opts = delimitedTextImportOptions("NumVariables", 13);

% Specify range and delimiter
opts.DataLines = [3, Inf];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["ANALYTICDATE","CURRENCY","POSITIONID_FE","DELTA","GAMMA","LEG","PORTFOLIOID_FE","REF_DATE","RHO","THETA","VEGA","RHO-1","TBRICKS_INSTRUMENT_ID"];
opts.VariableTypes = ["datetime","string","string","double","double","double","string","datetime","double","double","double","double","string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["POSITIONID_FE","PORTFOLIOID_FE","TBRICKS_INSTRUMENT_ID"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["POSITIONID_FE","DELTA","GAMMA","LEG","PORTFOLIOID_FE","RHO","THETA","VEGA","RHO-1"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "ANALYTICDATE", "InputFormat", "yyyy-MM-dd");
opts = setvaropts(opts, "REF_DATE", "InputFormat", "yyyy-MM-dd");
% Import the data
GREEKS_EOD = readtable(inputDataFolder + greeks_eod_fileName, opts);

GREEKS_EOD.LEG = [];

GREEKS_EOD(end,:)= [];

clear opts

%% COMBINE PORTFOLIO_EOD AND GREEKS EOD, THAN FILTERING

% 1st step: join my-Positions_EOD and GREEKS_EOD by POSITIONID
[pos_idx,opt_idx] = ismember(Positions_EOD.POSITIONID,GREEKS_EOD.POSITIONID_FE);

fieldsFromGreeks = setdiff(GREEKS_EOD.Properties.VariableNames,Positions_EOD.Properties.VariableNames);
GREEKS_EOD_toadd = removevars(GREEKS_EOD,setdiff(GREEKS_EOD.Properties.VariableNames,fieldsFromGreeks));
GREEKS_EOD_toadd = GREEKS_EOD_toadd(:,fieldsFromGreeks);

G_2_add_vartypes = varfun(@class, GREEKS_EOD_toadd, 'OutputFormat', 'cell');

sz = [numel(Positions_EOD.TBRICKS_INSTRUMENT_ID),numel(fieldsFromGreeks)];
newTable = table('Size',sz,'VariableTypes',G_2_add_vartypes,'VariableNames',fieldsFromGreeks);

opt_idx = opt_idx(opt_idx>0);
pos_idx = find(pos_idx>0);


for i = 1:numel(pos_idx)
    newTable(pos_idx(i),:) = GREEKS_EOD_toadd(opt_idx(i),:);
end

my_Positions_EOD = [Positions_EOD,newTable];

idx = isnan(my_Positions_EOD.QUANTITY);

my_Positions_EOD(idx,:)=[];

tempTable = varfun(@sum, my_Positions_EOD,'InputVariables',{'QUANTITY',...
                        'DELTA','GAMMA','RHO','RHO_1','THETA','VEGA'},...
                        'GroupingVariables',{'CURRENCY','INSTRUMENTID_FE',...
                        'MGROUP','MTYPE','PORTFOLIOID','TBRICKS_INSTRUMENT_ID'});
                    
idx = find(tempTable.sum_QUANTITY==0);
tempTable(idx,:) = [];
tempTable.GroupCount = [];
names = tempTable.Properties.VariableNames;
names = strrep(names,'sum_','');
tempTable.Properties.VariableNames = names;

my_Positions_EOD = tempTable;
clear opts

%% READ EOD OPTIONS 

% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 35);

% Specify range and delimiter
opts.DataLines = [3, Inf];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["AMERICAN_EUROPEAN", "CURRENCY", "DEALID_FE", "DELIVERY_DATE", "DESCRIPTION", "EXERCISE_STYLE", "EXPIRY", "EXPIRY_LABEL", "F_CALL_PUT", "F_CASH_DELIVERY", "F_QUANTO", "FORWARD_START_DATE", "FORWARD_START_STYLE", "INSTRUMENTID_FE", "LAST_TRADING_DATE", "LOTSIZE", "PORTFOLIOID", "REF_DATE", "SEC_CATEGORY", "SEC_GROUP", "SEC_TYPE", "STARTDATE", "STRIKE", "TRADE_DATE", "UNDERLYINGID", "FORWARD_START_END_DATE", "IS_FORWARD_START", "QUANTO_CURR", "NOMINAL", "DIVIDENDID_FE", "TBRICKS_INSTRUMENT_ID", "TBRICKS_UNDERLYING_ID", "TBRICKS_DIVIDEND_ID", "INITIAL_PRICE", "ISSUE_ID"];
opts.VariableTypes = ["string", "string", "double", "string", "string", "string", "datetime", "string", "string", "string", "string", "string", "double", "string", "string", "double", "string", "datetime", "string", "string", "string", "string", "double", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "double", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["DELIVERY_DATE", "DESCRIPTION", "F_QUANTO", "FORWARD_START_DATE", "INSTRUMENTID_FE", "LAST_TRADING_DATE", "PORTFOLIOID", "STARTDATE", "TRADE_DATE", "FORWARD_START_END_DATE", "QUANTO_CURR", "NOMINAL", "TBRICKS_INSTRUMENT_ID", "ISSUE_ID"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["AMERICAN_EUROPEAN", "CURRENCY", "DELIVERY_DATE", "DESCRIPTION", "EXERCISE_STYLE", "EXPIRY_LABEL", "F_CALL_PUT", "F_CASH_DELIVERY", "F_QUANTO", "FORWARD_START_DATE", "INSTRUMENTID_FE", "LAST_TRADING_DATE", "PORTFOLIOID", "SEC_CATEGORY", "SEC_GROUP", "SEC_TYPE", "STARTDATE", "TRADE_DATE", "UNDERLYINGID", "FORWARD_START_END_DATE", "IS_FORWARD_START", "QUANTO_CURR", "NOMINAL", "DIVIDENDID_FE", "TBRICKS_INSTRUMENT_ID", "TBRICKS_UNDERLYING_ID", "TBRICKS_DIVIDEND_ID", "ISSUE_ID"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "EXPIRY", "InputFormat", "yyyy-MM-dd");
opts = setvaropts(opts, "REF_DATE", "InputFormat", "yyyy-MM-dd");

% Import the data
Options_EOD = readtable(inputDataFolder + options_eod_fileName, opts);
Options_EOD(ismissing(Options_EOD.TBRICKS_INSTRUMENT_ID),:) = [];

% locate the var name to be used as key and chage its name
% col = find(strcmp(Options_EOD.Properties.VariableNames,'TBRICKS_UNDERLYING_ID'));
% Options_EOD.Properties.VariableNames{col} = 'key_1';

clear opts


%% READ Market Attributes

% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 15);

% Specify range and delimiter
opts.DataLines = [3, Inf];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["INSTRUMENTID_FE", "REF_DATE", "SEC_CATEGORY", "SEC_GROUP", "SEC_TYPE", "MARKET", "RIC0", "SYMBOL", "SEDOL", "MKT_SETTL_CONV", "EXCHANGE_MARKET_CODE", "FINAL_SETTLEMENT_DAYS", "TBRICKS_INSTRUMENT_ID", "MARKET_NAME", "F_IS_PRIMARY"];
opts.VariableTypes = ["string", "datetime", "string", "string", "string", "string", "double", "string", "string", "double", "string", "double", "string", "string", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["SEDOL", "EXCHANGE_MARKET_CODE"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["INSTRUMENTID_FE", "SEC_CATEGORY", "SEC_GROUP", "SEC_TYPE", "MARKET", "SYMBOL", "SEDOL", "EXCHANGE_MARKET_CODE", "TBRICKS_INSTRUMENT_ID", "MARKET_NAME", "F_IS_PRIMARY"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "REF_DATE", "InputFormat", "yyyy-MM-dd");

% Import the data
mktAttributes_EOD = readtable(inputDataFolder + mktAttributes_eod_fileName, opts);
mktAttributes_EOD(ismissing(mktAttributes_EOD.TBRICKS_INSTRUMENT_ID),:) = [];

% field names that are in mktAttributes_EOD, but not in Options_EOD
fieldsFromR = setdiff(mktAttributes_EOD.Properties.VariableNames,Options_EOD.Properties.VariableNames);
fieldsFromL = Options_EOD.Properties.VariableNames; % I want all fields from left table

clear opts

% re-assign Options_EOD including infos on underlying ID from table mktAttributes_EOD
[Options_EOD,iLeft,~] = outerjoin(Options_EOD,mktAttributes_EOD,'LeftKeys','TBRICKS_UNDERLYING_ID', ...
    'RightKeys','TBRICKS_INSTRUMENT_ID',...
    'LeftVariables',fieldsFromL ,'RightVariables',fieldsFromR,'Type','left','MergeKeys',false);

[C,ia,ic] = unique(iLeft);
Options_EOD = Options_EOD(C,:);


%% READ EOD FUTURES 

opts = delimitedTextImportOptions("NumVariables", 22);

% Specify range and delimiter
opts.DataLines = [3, Inf];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["CURRENCY", "DELIVERY_ENDDATE", "DELIVERY_STARTDATE", "DESCRIPTION", "EXPIRY", "EXPIRY_LABEL", "F_CASH_DELIVERY", "F_LISTED", "INSTRUMENTID_FE", "ISIN", "LOTSIZE", "REF_DATE", "SEC_CATEGORY", "SEC_GROUP", "SEC_TYPE", "UNDERLYINGID", "DIV_FUTURE_TYPE", "F_DIV_FUTURE", "DIVIDENDID_FE", "TBRICKS_INSTRUMENT_ID", "TBRICKS_UNDERLYING_ID", "TBRICKS_DIVIDEND_ID"];
opts.VariableTypes = ["string", "string", "string", "string", "datetime", "double", "string", "string", "string", "string", "double", "datetime", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["DELIVERY_ENDDATE", "DELIVERY_STARTDATE", "DESCRIPTION", "F_LISTED", "INSTRUMENTID_FE", "ISIN", "UNDERLYINGID", "DIV_FUTURE_TYPE", "DIVIDENDID_FE", "TBRICKS_INSTRUMENT_ID", "TBRICKS_UNDERLYING_ID", "TBRICKS_DIVIDEND_ID"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["CURRENCY", "DELIVERY_ENDDATE", "DELIVERY_STARTDATE", "DESCRIPTION", "F_CASH_DELIVERY", "F_LISTED", "INSTRUMENTID_FE", "ISIN", "SEC_CATEGORY", "SEC_GROUP", "SEC_TYPE", "UNDERLYINGID", "DIV_FUTURE_TYPE", "F_DIV_FUTURE", "DIVIDENDID_FE", "TBRICKS_INSTRUMENT_ID", "TBRICKS_UNDERLYING_ID", "TBRICKS_DIVIDEND_ID"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "EXPIRY", "InputFormat", "yyyy-MM-dd");
opts = setvaropts(opts, "REF_DATE", "InputFormat", "yyyy-MM-dd");
opts = setvaropts(opts, "EXPIRY_LABEL", "TrimNonNumeric", true);
opts = setvaropts(opts, "EXPIRY_LABEL", "ThousandsSeparator", ",");
% Import the data
Futures_EOD = readtable(inputDataFolder + futures_eod_fileName, opts);

Futures_EOD.ISIN = [];

clear opts

%% READ ISIN 

opts = delimitedTextImportOptions("NumVariables", 26);

% Specify range and delimiter
opts.DataLines = [3, Inf];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["DEALID_FE","DESCRIPTION","F_ISLISTED","INSTRUMENT_FE","INSTRUMENTID_FE","TBRICKS_INSTRUMENT_ID","ISIN","ISSUERID","MFAMILY","MGROUP","MTYPE","PHASE","PORTFOLIOID","REF_DATE","SEC_CATEGORY","SEC_GROUP","SEC_TYPE","TYPOLOGY","PRICE_MULTIPLIER","CFI_CODE","USE_VOLATILITY_SURFACE","CUSTOM_UNIQUE_ID","BASE_PRICE_MULTIPLIER","SUMMATION_GROUP","CFI_VARIANT_NAME","INSTRUMENTNUM_FE"];
opts.VariableTypes = ["double", "string", "string", "string","string","string","string","string","string","string","string","double","string","datetime","string","string","string","string","double","string","string","string","double","string","string","double",];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["DESCRIPTION","INSTRUMENT_FE","INSTRUMENTID_FE","TBRICKS_INSTRUMENT_ID","ISIN","ISSUERID","MTYPE","SEC_CATEGORY","CFI_VARIANT_NAME"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["DESCRIPTION","ISIN","ISSUERID","PORTFOLIOID","TYPOLOGY","CUSTOM_UNIQUE_ID","CFI_VARIANT_NAME","INSTRUMENTNUM_FE"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "REF_DATE", "InputFormat", "yyyy-MM-dd");
% Import the data
ISIN_EOD = readtable(inputDataFolder + isin_eod_fileName, opts);

ISIN_EOD(end,:)= [];

clear opts


%% PUT EVERYTHING TOGETHER IN THE FINAL mainPtfTable (in 2 steps)

% % 1) left join between Positions_EOD and Options_EOD on the field
% % 'TBRICKS_INSTRUMENT_ID'
% 
% % field names that are in Options_EOD, but not in Positions_EOD
% fieldsFromR = setdiff(Options_EOD.Properties.VariableNames,my_Positions_EOD.Properties.VariableNames);
% fieldsFromL = my_Positions_EOD.Properties.VariableNames; % I want all fields from left table
% 
% [mainPtfTable,iLeft,iRight] = outerjoin(my_Positions_EOD,Options_EOD,'keys','TBRICKS_INSTRUMENT_ID', ...
%     'LeftVariables',fieldsFromL ,'RightVariables',fieldsFromR, 'Type','left');
% [C,ia,ic] = unique(iLeft);
% mainPtfTable = mainPtfTable(C,:);
% 
% % 2) left join between mainPtfTable and Futures_EOD on the field
% % 'TBRICKS_INSTRUMENT_ID'
% 
% % field names that are in Futures_EOD, but not in mainPtfTable
% fieldsFromR = setdiff(Futures_EOD.Properties.VariableNames,mainPtfTable.Properties.VariableNames);
% fieldsFromL = mainPtfTable.Properties.VariableNames; % I want all fields from left table
% 
% mainPtfTable = outerjoin(mainPtfTable,Futures_EOD,'keys','TBRICKS_INSTRUMENT_ID', ...
%     'LeftVariables',fieldsFromL ,'RightVariables',fieldsFromR, 'Type','left');
% 
% % field names that are in ISIN_EOD, but not in mainPtfTable
% fieldsFromR = setdiff(ISIN_EOD.Properties.VariableNames,mainPtfTable.Properties.VariableNames);
% fieldsFromL = mainPtfTable.Properties.VariableNames; % I want all fields from left table
% 
% mainPtfTable = outerjoin(mainPtfTable,ISIN_EOD,'keys','TBRICKS_INSTRUMENT_ID', ...
%     'LeftVariables',fieldsFromL ,'RightVariables',fieldsFromR, 'Type','left');
% 
% 
% % field names that are in GREEKS_EOD, but not in mainPtfTable
% fieldsFromR = setdiff(GREEKS_EOD.Properties.VariableNames,mainPtfTable.Properties.VariableNames);
% fieldsFromL = Position_EOD.Properties.VariableNames; % I want all fields from left table
% 
% mainPtfTable = outerjoin(mainPtfTable,GREEKS_EOD,'keys','TBRICKS_INSTRUMENT_ID', ...
%     'LeftVariables',fieldsFromL ,'RightVariables',fieldsFromR, 'Type','left');
% 
% writetable(mainPtfTable,'mainPtfTable.xlsx')

%% alternative way to compose the table

mainPtfTable = [];

% 1st step: join Futures:EOD and Options_EOD

fieldsFromOptions = setdiff(Options_EOD.Properties.VariableNames,Futures_EOD.Properties.VariableNames);
fieldsFromFutures = setdiff(Futures_EOD.Properties.VariableNames,Options_EOD.Properties.VariableNames);

F_2_add_vartypes = varfun(@class, Futures_EOD(:,fieldsFromFutures), 'OutputFormat', 'cell');
O_2_add_vartypes = varfun(@class, Options_EOD(:,fieldsFromOptions), 'OutputFormat', 'cell');
szopt = [size(Options_EOD,1),numel(fieldsFromFutures)];
szfut = [size(Futures_EOD,1),numel(fieldsFromOptions)];

newTableOpt = table('Size',szopt,'VariableTypes',F_2_add_vartypes,'VariableNames',fieldsFromFutures);
newTableFut = table('Size',szfut,'VariableTypes',O_2_add_vartypes,'VariableNames',fieldsFromOptions);

Options_EOD = [Options_EOD, newTableOpt];
Futures_EOD = [Futures_EOD, newTableFut];

orderedFields = unique(Options_EOD.Properties.VariableNames);

Options_EOD = Options_EOD(:,orderedFields);
Futures_EOD = Futures_EOD(:,orderedFields);

Options_Futures_EOD = [Options_EOD; Futures_EOD];

% 2nd step: join the new Options_Futures_EOD with my_Positions_EOD

[pos_idx,opt_idx] = ismember(my_Positions_EOD.TBRICKS_INSTRUMENT_ID,Options_Futures_EOD.TBRICKS_INSTRUMENT_ID);

fieldsFromOptions = setdiff(Options_Futures_EOD.Properties.VariableNames,my_Positions_EOD.Properties.VariableNames);
Options_EOD_toadd = removevars(Options_Futures_EOD,setdiff(Options_Futures_EOD.Properties.VariableNames,fieldsFromOptions));
Options_EOD_toadd = Options_EOD_toadd(:,fieldsFromOptions);

O_2_add_vartypes = varfun(@class, Options_EOD_toadd, 'OutputFormat', 'cell');

sz = [numel(my_Positions_EOD.TBRICKS_INSTRUMENT_ID),numel(fieldsFromOptions)];
newTable = table('Size',sz,'VariableTypes',O_2_add_vartypes,'VariableNames',fieldsFromOptions);

opt_idx = opt_idx(opt_idx>0);
pos_idx = find(pos_idx>0);


for i = 1:numel(pos_idx)
    newTable(pos_idx(i),:) = Options_EOD_toadd(opt_idx(i),:);
end

mainPtfTable = [my_Positions_EOD,newTable];

% 3rd step: join the mainPtfTable with ISIN_EOD

[pos_idx,isin_idx] = ismember(mainPtfTable.TBRICKS_INSTRUMENT_ID,ISIN_EOD.TBRICKS_INSTRUMENT_ID);

fieldsFromISIN= setdiff(ISIN_EOD.Properties.VariableNames,mainPtfTable.Properties.VariableNames);
ISIN_EOD_toadd = removevars(ISIN_EOD,setdiff(ISIN_EOD.Properties.VariableNames,fieldsFromISIN));
ISIN_EOD_toadd = ISIN_EOD_toadd(:,fieldsFromISIN);

O_2_add_vartypes = varfun(@class, ISIN_EOD_toadd, 'OutputFormat', 'cell');

sz = [numel(mainPtfTable.TBRICKS_INSTRUMENT_ID),numel(fieldsFromISIN)];
newTable = table('Size',sz,'VariableTypes',O_2_add_vartypes,'VariableNames',fieldsFromISIN);

isin_idx = isin_idx(isin_idx>0);
pos_idx = find(pos_idx>0);


for i = 1:numel(pos_idx)
    newTable(pos_idx(i),:) = ISIN_EOD_toadd(isin_idx(i),:);
end

mainPtfTable = [mainPtfTable,newTable];

%% create a column with the underlying ISIN (if any and if is mapped)

und_tb_code = unique(mainPtfTable.TBRICKS_UNDERLYING_ID);
und_tb_code = rmmissing(und_tb_code);
und_isin = table('Size',size(mainPtfTable.ISIN),'VariableNames',"UNDERLYING_ISIN",'VariableType',"string");

for i = 1:numel(und_tb_code)
    % find the code in ISIN_EOD
    isin_idx = strcmp(und_tb_code{i},ISIN_EOD.TBRICKS_INSTRUMENT_ID);
    isin = ISIN_EOD.ISIN(isin_idx);
    aa = strcmp(und_tb_code{i},mainPtfTable.TBRICKS_UNDERLYING_ID);
    if ~isempty(aa)
        und_isin.UNDERLYING_ISIN(aa,:) = isin;
    end
end

mainPtfTable = [mainPtfTable,und_isin]; 

% get data from bbg using ISIN code

%% get data from bbg
isin_list = unique(mainPtfTable.ISIN);
isin_list = strcat('/ISIN/',isin_list);


N = size(isin_list,1);
% get the fields: EQ_FUND_CODE TICKER 
uparams.fields = {'DX895','TICKER'};
uparams.override_fields = [];
uparams.history_start_date = today();
uparams.history_end_date = today();
uparams.DataFromBBG = DataFromBBG;


for k=1:N
    k,N
    uparams.ticker = isin_list{k,1};
    U = Utilities(uparams);
    U.GetBBG_StaticData;
    
    % EQ_FUND_CODE
    if isempty(U.Output.BBG_getdata.DX895{:})
        isin_list{k,2} = 'N/A';
    else
        isin_list{k,2} = strcat(U.Output.BBG_getdata.DX895{:},' Equity');
    end  
    % TICKER
    if isempty(U.Output.BBG_getdata.TICKER{:})
        isin_list{k,3} = 'N/A';
    else
        isin_list{k,3} = strcat(U.Output.BBG_getdata.TICKER{:},' Equity');
    end 
 
end

InfoTable = array2table(isin_list(:,2:end));
InfoTable.Properties.VariableNames = {'EQ_FUND_CODE' 'TICKER'};

writetable(mainPtfTable,'mainPtfTable.xlsx');
