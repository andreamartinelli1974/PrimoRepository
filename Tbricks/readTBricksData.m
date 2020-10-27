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


positions_eod_fileName = "SSL_PCG_POSITION_TBRX_30200831.txt";
futures_eod_fileName = "SSL_PCG_FI_FUTURE_TBRX_30200831.txt";
options_eod_fileName = "SSL_PCG_FI_OPTION_TBRX_30200831.txt";
mktAttributes_eod_fileName = "SSL_PCG_FI_MARKET_ATTRIBUTES_TBRX_30200831.txt";
isin_eod_fileName = "SSL_PCG_FI_TBRX_30200831.txt";
greeks_eod_fileName = "SSL_FCHUB_POSITION_ANALYTICS_GREEKS_TBRX_30200831.txt";

equityDeskPtf = {'AA2','ALPHA_SHORT','BT','DIRGENERALE','DISPERSION'...
                 'EQ_SHORT_TERM','EQUITY_CM','G WEST','IPO_US','LONG_ONLY'...
                 'LONG_TERM','QUANTO','QUANTO_2','RELATIVE09','RISK_ARB',...
                 'SPMIB','STAT_ARB','STRATEGIC','SYST_VOL','TEAM_STRAT',...
                 'TECNICO','TP-DIREZIONALE','VOLTRADING'};

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
opts = delimitedTextImportOptions("NumVariables", 30);

% Specify range and delimiter
opts.DataLines = [3, Inf];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["POSPRICE", "BASECURR_PORTCURR", "POSITIONID", "F_PURGED",...
    "QUANTITY", "QUANTITY_BUY", "QUOTCURR_PORTCURR", "POSPRICE_BUY", "PORTFOLIOID",...
    "QUANTITY_SELL", "CURRENCY", "SSL_SNAPSHOT_DATE", "SSL_FEID", "POSPRICE_SELL",...
    "FIID", "PORTFOLIOID_FE", "REF_DATE", "POSITIONID_FE", "INSTRUMENT_FE", "MFAMILY",...
    "MGROUP", "MTYPE", "PL_KEY_FE","RSKSECTION","TYPOLOGY","USAGE","INTRADAY",...
    "QUANTITY_LIVE","SRC_ENTITYID","EQUIVALENT_POSITION"];
opts.VariableTypes = ["double", "string", "string", "string",...
    "double", "double", "string", "string", "string",...
    "double", "string", "datetime", "string", "string",...
    "string", "string", "datetime", "string", "string", "string",...
    "string", "string", "string", "string", "string", "string", "string",...
    "string", "string", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["POSITIONID", "PORTFOLIOID", "FIID", "PORTFOLIOID_FE",...
    "POSITIONID_FE", "INSTRUMENT_FE", "MFAMILY", "MGROUP", "MTYPE"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["POSPRICE", "BASECURR_PORTCURR", "POSITIONID", "F_PURGED",...
    "QUANTITY", "QUANTITY_BUY", "QUOTCURR_PORTCURR", "POSPRICE_BUY", "PORTFOLIOID",...
    "QUANTITY_SELL", "CURRENCY", "SSL_SNAPSHOT_DATE", "SSL_FEID", "POSPRICE_SELL",...
    "FIID", "PORTFOLIOID_FE", "REF_DATE", "POSITIONID_FE", "INSTRUMENT_FE", "MFAMILY",...
    "MGROUP", "MTYPE", "PL_KEY_FE","RSKSECTION","TYPOLOGY","USAGE","INTRADAY",...
    "QUANTITY_LIVE","SRC_ENTITYID","EQUIVALENT_POSITION"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, ["SSL_SNAPSHOT_DATE","REF_DATE"], "InputFormat", "yyyyMMdd");

% Import the data
Positions_EOD = readtable(inputDataFolder + positions_eod_fileName, opts);

%% READ GREEKS

opts = delimitedTextImportOptions("NumVariables", 33);

% Specify range and delimiter
opts.DataLines = [3, Inf];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["YTM","VEGA","DELTA_EXCHANGE_NPV","POSITIONID","STRIKE_REF_SPOT",...
                      "DELTA_FACTOR","GAMMA","RHO_FACTOR","DELTA","RHO","BPV","REF_DATE",...
                      "PVBP","GAMMA_FACTOR","SSL_SNAPSHOT_DATE","ANALYTICDATE","THETA",...
                      "SSL_FEID","VEGA_FACTOR","DELTA_EXCHANGE_LIAB","RISK_NATURE",...
                      "DELTA_EXCHANGE_CASH","CURRENCY","STEP_LABEL","POSITIONID_FE",...
                      "STRIKE_REF_VALUE","STRIKE_UNDERLYING","F_DELTA_EXCHANGE",...
                      "STRIKE_INSTR_VALUE","STRIKE_INSTR_VALUE","VOLATILITY",...
                      "THETA_FACTOR","SSL_COUNTER","RHO1"];
opts.VariableTypes = ["string","double","string","string","string",...
                      "string","double","string","double","double","string","datetime",...
                      "string","string","double","datetime","double",...
                      "string","string","string","string",...
                      "string","string","string","string",...
                      "string","string","string",...
                      "string","string","string",...
                      "string","string","double",];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["POSITIONID","POSITIONID_FE"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["YTM","VEGA","DELTA_EXCHANGE_NPV","POSITIONID","STRIKE_REF_SPOT",...
                      "DELTA_FACTOR","GAMMA","RHO_FACTOR","DELTA","RHO","BPV","REF_DATE",...
                      "PVBP","GAMMA_FACTOR","SSL_SNAPSHOT_DATE","ANALYTICDATE","THETA",...
                      "SSL_FEID","VEGA_FACTOR","DELTA_EXCHANGE_LIAB","RISK_NATURE",...
                      "DELTA_EXCHANGE_CASH","CURRENCY","STEP_LABEL","POSITIONID_FE",...
                      "STRIKE_REF_VALUE","STRIKE_UNDERLYING","F_DELTA_EXCHANGE",...
                      "STRIKE_INSTR_VALUE","STRIKE_INSTR_VALUE","VOLATILITY",...
                      "THETA_FACTOR","SSL_COUNTER","RHO1"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, ["REF_DATE","ANALYTICDATE"], "InputFormat", "yyyyMMdd");
% Import the data
GREEKS_EOD = readtable(inputDataFolder + greeks_eod_fileName, opts);

GREEKS_EOD(end,:)= [];

clear opts

%% COMBINE PORTFOLIO_EOD AND GREEKS EOD, THAN FILTERING

% 1st step: join my-Positions_EOD and GREEKS_EOD by POSITIONID
[pos_idx,opt_idx] = ismember(Positions_EOD.POSITIONID_FE,GREEKS_EOD.POSITIONID_FE);

fieldsFromGreeks = setdiff(GREEKS_EOD.Properties.VariableNames,Positions_EOD.Properties.VariableNames);
GREEKS_EOD_toadd = removevars(GREEKS_EOD,setdiff(GREEKS_EOD.Properties.VariableNames,fieldsFromGreeks));
GREEKS_EOD_toadd = GREEKS_EOD_toadd(:,fieldsFromGreeks);

G_2_add_vartypes = varfun(@class, GREEKS_EOD_toadd, 'OutputFormat', 'cell');

sz = [numel(Positions_EOD.FIID),numel(fieldsFromGreeks)];
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
                        'DELTA','GAMMA','RHO','THETA','VEGA'},...
                        'GroupingVariables',{'CURRENCY',...
                        'MGROUP','MTYPE','PORTFOLIOID_FE','FIID'});
                    
idx = find(tempTable.sum_QUANTITY==0);
tempTable(idx,:) = [];
tempTable.GroupCount = [];
names = tempTable.Properties.VariableNames;
names = strrep(names,'sum_','');
tempTable.Properties.VariableNames = names;

my_Positions_EOD = tempTable;
clear opts

%% READ EOD OPTIONS 

% % Setup the Import Options and import the data
% opts = delimitedTextImportOptions("NumVariables", 133);
% 
% % Specify range and delimiter
% opts.DataLines = [3, Inf];
% opts.Delimiter = "\t";
% 
% % Specify column names and types
% opts.VariableNames = ["AMERICAN_EUROPEAN", "CURRENCY", "DEALID_FE", "DELIVERY_DATE", "DESCRIPTION", "EXERCISE_STYLE", "EXPIRY", "EXPIRY_LABEL", "F_CALL_PUT", "F_CASH_DELIVERY", "F_QUANTO", "FORWARD_START_DATE", "FORWARD_START_STYLE", "INSTRUMENTID_FE", "LAST_TRADING_DATE", "LOTSIZE", "PORTFOLIOID", "REF_DATE", "SEC_CATEGORY", "SEC_GROUP", "SEC_TYPE", "STARTDATE", "STRIKE", "TRADE_DATE", "UNDERLYINGID", "FORWARD_START_END_DATE", "IS_FORWARD_START", "QUANTO_CURR", "NOMINAL", "DIVIDENDID_FE", "FIID", "TBRICKS_UNDERLYING_ID", "TBRICKS_DIVIDEND_ID", "INITIAL_PRICE", "ISSUE_ID"];
% opts.VariableTypes = ["string", "string", "double", "string", "string", "string", "datetime", "string", "string", "string", "string", "string", "double", "string", "string", "double", "string", "datetime", "string", "string", "string", "string", "double", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "double", "string"];
% 
% % Specify file level properties
% opts.ExtraColumnsRule = "ignore";
% opts.EmptyLineRule = "read";
% 
% % Specify variable properties
% opts = setvaropts(opts, ["DELIVERY_DATE", "DESCRIPTION", "F_QUANTO", "FORWARD_START_DATE", "INSTRUMENTID_FE", "LAST_TRADING_DATE", "PORTFOLIOID", "STARTDATE", "TRADE_DATE", "FORWARD_START_END_DATE", "QUANTO_CURR", "NOMINAL", "FIID", "ISSUE_ID"], "WhitespaceRule", "preserve");
% opts = setvaropts(opts, ["AMERICAN_EUROPEAN", "CURRENCY", "DELIVERY_DATE", "DESCRIPTION", "EXERCISE_STYLE", "EXPIRY_LABEL", "F_CALL_PUT", "F_CASH_DELIVERY", "F_QUANTO", "FORWARD_START_DATE", "INSTRUMENTID_FE", "LAST_TRADING_DATE", "PORTFOLIOID", "SEC_CATEGORY", "SEC_GROUP", "SEC_TYPE", "STARTDATE", "TRADE_DATE", "UNDERLYINGID", "FORWARD_START_END_DATE", "IS_FORWARD_START", "QUANTO_CURR", "NOMINAL", "DIVIDENDID_FE", "FIID", "TBRICKS_UNDERLYING_ID", "TBRICKS_DIVIDEND_ID", "ISSUE_ID"], "EmptyFieldRule", "auto");
% opts = setvaropts(opts, "EXPIRY", "InputFormat", "yyyyMMdd");
% opts = setvaropts(opts, "REF_DATE", "InputFormat", "yyyy-MM-dd");

% Import the data
Options_EOD = readtable(inputDataFolder + options_eod_fileName); %, opts);

% remove missing FIID & NaN colums
Options_EOD(ismissing(Options_EOD.FIID),:) = [];
Options_EOD(ismissing(Options_EOD.STRIKE),:) = [];
Options_EOD = rmmissing(Options_EOD,2);

%format some column
Options_EOD.EXPIRY = datetime(num2str(Options_EOD.EXPIRY), 'format', 'yyyyMMdd'); 
Options_EOD.REF_DATE = datetime(num2str(Options_EOD.REF_DATE), 'format', 'yyyyMMdd'); 
Options_EOD.UNDERLYINGID = string(Options_EOD.UNDERLYINGID);
Options_EOD.FIID = string(Options_EOD.FIID);
Options_EOD.CURRENCY = string(Options_EOD.CURRENCY);
Options_EOD.F_CALL_PUT = string(Options_EOD.F_CALL_PUT);
Options_EOD.EXPIRY_LABEL = string(Options_EOD.EXPIRY_LABEL);
Options_EOD.EXERCISE_STYLE = string(Options_EOD.EXERCISE_STYLE);

%% READ EOD FUTURES 

% opts = delimitedTextImportOptions("NumVariables", 22);
% 
% % Specify range and delimiter
% opts.DataLines = [3, Inf];
% opts.Delimiter = "\t";
% 
% % Specify column names and types
% opts.VariableNames = ["CURRENCY", "DELIVERY_ENDDATE", "DELIVERY_STARTDATE", "DESCRIPTION", "EXPIRY", "EXPIRY_LABEL", "F_CASH_DELIVERY", "F_LISTED", "INSTRUMENTID_FE", "ISIN", "LOTSIZE", "REF_DATE", "SEC_CATEGORY", "SEC_GROUP", "SEC_TYPE", "UNDERLYINGID", "DIV_FUTURE_TYPE", "F_DIV_FUTURE", "DIVIDENDID_FE", "FIID", "TBRICKS_UNDERLYING_ID", "TBRICKS_DIVIDEND_ID"];
% opts.VariableTypes = ["string", "string", "string", "string", "datetime", "double", "string", "string", "string", "string", "double", "datetime", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string"];
% 
% % Specify file level properties
% opts.ExtraColumnsRule = "ignore";
% opts.EmptyLineRule = "read";
% 
% % Specify variable properties
% opts = setvaropts(opts, ["DELIVERY_ENDDATE", "DELIVERY_STARTDATE", "DESCRIPTION", "F_LISTED", "INSTRUMENTID_FE", "ISIN", "UNDERLYINGID", "DIV_FUTURE_TYPE", "DIVIDENDID_FE", "FIID", "TBRICKS_UNDERLYING_ID", "TBRICKS_DIVIDEND_ID"], "WhitespaceRule", "preserve");
% opts = setvaropts(opts, ["CURRENCY", "DELIVERY_ENDDATE", "DELIVERY_STARTDATE", "DESCRIPTION", "F_CASH_DELIVERY", "F_LISTED", "INSTRUMENTID_FE", "ISIN", "SEC_CATEGORY", "SEC_GROUP", "SEC_TYPE", "UNDERLYINGID", "DIV_FUTURE_TYPE", "F_DIV_FUTURE", "DIVIDENDID_FE", "FIID", "TBRICKS_UNDERLYING_ID", "TBRICKS_DIVIDEND_ID"], "EmptyFieldRule", "auto");
% opts = setvaropts(opts, "EXPIRY", "InputFormat", "yyyy-MM-dd");
% opts = setvaropts(opts, "REF_DATE", "InputFormat", "yyyy-MM-dd");
% opts = setvaropts(opts, "EXPIRY_LABEL", "TrimNonNumeric", true);
% opts = setvaropts(opts, "EXPIRY_LABEL", "ThousandsSeparator", ",");

% Import the data
Futures_EOD = readtable(inputDataFolder + futures_eod_fileName); %, opts);% remove missing FIID & NaN colums
Futures_EOD(ismissing(Futures_EOD.FIID),:) = [];
Futures_EOD = rmmissing(Futures_EOD,2);

% Format some columns
Futures_EOD.FIID = string(Futures_EOD.FIID);
Futures_EOD.UNDERLYINGID = string(Futures_EOD.UNDERLYINGID);
Futures_EOD.REF_DATE = datetime(num2str(Futures_EOD.REF_DATE), 'format', 'yyyyMMdd');
Futures_EOD.EXPIRY = datetime(num2str(Futures_EOD.EXPIRY), 'format', 'yyyyMMdd');

clear opts

%% READ ISIN 

opts = delimitedTextImportOptions("NumVariables", 38);

% Specify range and delimiter
opts.DataLines = [3, Inf];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["ASSETCLASS_DES","NEW_MTYPE","DESCRIPTION_EXT","FI_TYPE",...
                      "NUMBEROFPHASES","INSTRUMENT_FE","ASSETCLASS","NEW_MGROUP",...
                      "SSL_FEID","SEC_REFERENCE","F_ISLISTED","TYPOLOGY_DES",...
                      "SEC_GROUP","DESCRIPTION","COMMENT1","COMMENT0",...
                      "COMMENT2","ISSUERID","TYPE_DES","FIID",...
                      "SEC_TYPE","PHASE","ISIN","GROUP_DES",...
                      "INSTRUMENTID_FE","MTYPE","FAMILY_DES","NEW_MFAMILY"...
                      "F_LABELCHG","SSL_SNAPSHOT_DATE","TYPOLOGY","MFAMILY",...
                      "SEC_CATEGORY","REF_DATE","NEW_TYPOLOGY","STRUCTID_FE",...
                      "INSTRUMENTNUM_FE","MGROUP","QUANTITYFACTOR"];
opts.VariableTypes = ["string", "string", "string", "string",...
                      "double", "string", "string", "string",...
                      "string", "string", "string", "string",...
                      "string", "string", "string", "string",...
                      "string", "string", "string", "string",...
                      "string", "double", "string", "string",...
                      "string", "string", "string", "string",...
                      "string", "double", "string", "string",...
                      "string", "datetime", "string", "string",...
                      "double", "string", "string"];
% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["NEW_MTYPE","INSTRUMENT_FE","NEW_MGROUP","DESCRIPTION","FIID","SEC_TYPE","ISIN","INSTRUMENTID_FE","SEC_CATEGORY"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["ASSETCLASS_DES","NEW_MTYPE","DESCRIPTION_EXT","FI_TYPE",...
                         "NUMBEROFPHASES","INSTRUMENT_FE","ASSETCLASS","NEW_MGROUP",...
                         "SSL_FEID","SEC_REFERENCE","F_ISLISTED","TYPOLOGY_DES",...
                         "SEC_GROUP","DESCRIPTION","COMMENT1","COMMENT0",...
                         "COMMENT2","ISSUERID","TYPE_DES","FIID",...
                         "SEC_TYPE","PHASE","ISIN","GROUP_DES",...
                         "INSTRUMENTID_FE","MTYPE","FAMILY_DES","NEW_MFAMILY"...
                         "F_LABELCHG","SSL_SNAPSHOT_DATE","TYPOLOGY","MFAMILY",...
                         "SEC_CATEGORY","REF_DATE","NEW_TYPOLOGY","STRUCTID_FE",...
                         "INSTRUMENTNUM_FE","MGROUP","QUANTITYFACTOR"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "REF_DATE", "InputFormat", "yyyyMMdd");
% Import the data
ISIN_EOD = readtable(inputDataFolder + isin_eod_fileName, opts);

ISIN_EOD(end,:)= [];

clear opts


%% COMPOSING THE MAIN TABLE

mainPtfTable = [];

% 1st step: join Futures_EOD and Options_EOD

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

[pos_idx,opt_idx] = ismember(my_Positions_EOD.FIID,Options_Futures_EOD.FIID);

fieldsFromOptions = setdiff(Options_Futures_EOD.Properties.VariableNames,my_Positions_EOD.Properties.VariableNames);
Options_EOD_toadd = removevars(Options_Futures_EOD,setdiff(Options_Futures_EOD.Properties.VariableNames,fieldsFromOptions));
Options_EOD_toadd = Options_EOD_toadd(:,fieldsFromOptions);

O_2_add_vartypes = varfun(@class, Options_EOD_toadd, 'OutputFormat', 'cell');

sz = [numel(my_Positions_EOD.FIID),numel(fieldsFromOptions)];
newTable = table('Size',sz,'VariableTypes',O_2_add_vartypes,'VariableNames',fieldsFromOptions);

opt_idx = opt_idx(opt_idx>0);
pos_idx = find(pos_idx>0);


for i = 1:numel(pos_idx)
    newTable(pos_idx(i),:) = Options_EOD_toadd(opt_idx(i),:);
end

mainPtfTable = [my_Positions_EOD,newTable];

% 3rd step: join the mainPtfTable with ISIN_EOD

[pos_idx,isin_idx] = ismember(mainPtfTable.FIID,ISIN_EOD.FIID);

fieldsFromISIN= setdiff(ISIN_EOD.Properties.VariableNames,mainPtfTable.Properties.VariableNames);
ISIN_EOD_toadd = removevars(ISIN_EOD,setdiff(ISIN_EOD.Properties.VariableNames,fieldsFromISIN));
ISIN_EOD_toadd = ISIN_EOD_toadd(:,fieldsFromISIN);

O_2_add_vartypes = varfun(@class, ISIN_EOD_toadd, 'OutputFormat', 'cell');

sz = [numel(mainPtfTable.FIID),numel(fieldsFromISIN)];
newTable = table('Size',sz,'VariableTypes',O_2_add_vartypes,'VariableNames',fieldsFromISIN);

isin_idx = isin_idx(isin_idx>0);
pos_idx = find(pos_idx>0);


for i = 1:numel(pos_idx)
    newTable(pos_idx(i),:) = ISIN_EOD_toadd(isin_idx(i),:);
end

mainPtfTable = [mainPtfTable,newTable];

%% create a column with the underlying ISIN (if any and if is mapped)

und_tb_code = unique(mainPtfTable.UNDERLYINGID);
und_tb_code = rmmissing(und_tb_code);
und_isin = table('Size',size(mainPtfTable.ISIN),'VariableNames',"UNDERLYING_ISIN",'VariableType',"string");

for i = 1:numel(und_tb_code)
    % find the code in ISIN_EOD
    isin_idx = strcmp(und_tb_code{i},ISIN_EOD.FIID);
    isin = ISIN_EOD.ISIN(isin_idx);
    aa = find(strcmp(und_tb_code{i},mainPtfTable.UNDERLYINGID));
    if ~isempty(aa)
        und_isin.UNDERLYING_ISIN(aa,:) = isin;
    end
end

mainPtfTable = [mainPtfTable,und_isin]; 


%% translate data
params.EquityPtfNames = equityDeskPtf;
params.DataFromBBG = DataFromBBG;
params.mainPtfTable = mainPtfTable;

myTranslator = TBricksTranslator(params);

%% get data from bbg using ISIN code

% get data from bbg
[isin_list, idx, ~] = unique(mainPtfTable.ISIN);
isin_list = strcat('/ISIN/',isin_list);
isin_list(:,2)= mainPtfTable.INSTRUMENTID_FE(idx,:);
isin_list(:,3)= mainPtfTable.MGROUP(idx,:);



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
        isin_list{k,4} = 'N/A';
    else
        isin_list{k,4} = strcat(U.Output.BBG_getdata.DX895{:},' Equity');
    end  
    % TICKER
    if isempty(U.Output.BBG_getdata.TICKER{:})
        isin_list{k,5} = 'N/A';
    else
        isin_list{k,5} = strcat(U.Output.BBG_getdata.TICKER{:},' Equity');
    end 
 
end
isin_list(:,6)= mainPtfTable.UNDERLYING_ISIN(idx,:);

InfoTable = array2table(isin_list);
InfoTable.Properties.VariableNames = {'ISIN','INSTRUMENT_FE','MGROUP','EQ_FUND_CODE','TICKER','UNDERLYING_ISIN'};

%%
writetable(mainPtfTable,'mainPtfTable.xlsx');
