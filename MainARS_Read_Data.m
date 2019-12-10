%%% This mail is just to test all the functions needed to read and
%%% elaborate the input files for ARS_Trading_Tool 

clc; clear all; close all;

userId = getenv('USERNAME');
addpath(['C:\Users\' userId '\Documents\GitHub\Utilities']);

%%% INITIAL PARAMETERS %%%
data_dir = 'C:\Users\u093799\Documents\GitHub\PrimoRepository\Data\';
signal_history_file = 'Signals_traded_LIVE _Copy.xlsx';
use_previous_n_days = 2;


%% **************** STRUCTURE TO ACCESS BLOOMBERG DATA ********************

DataFromBBG.save2disk = true(1); % false(1); % True to save all Bloomberg calls to disk for future retrieval
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

%% check for new input files and load them

dir_content = dir([data_dir,'*.xlsx']);
files_to_check = {dir_content.name};
new_files = [];

old_data = [];
InputTables = [];
newlastUpdate = NaT(1);

if isfile('DataStoring.mat')
    load('Datastoring.mat');
    lastUpdate = DataStoring.lastUpdate;
    signal_table = DataStoring.signal_table;
    old_files = DataStoring.filenames;
    new_files = setdiff(files_to_check,old_files);
    if ~isempty(new_files)
        % deal with the new files
        disp('new files found');
        new_names = regexprep(new_files,'[^a-zA-Z0-9]','_');
        new_names = erase(new_names,'_xlsx');
    else
        disp('no new files');
        new_files = {};
    end
else
    DataStoring.DataTable = [];
    new_files = files_to_check;
    new_names = regexprep(files_to_check,'[^a-zA-Z0-9]','_');
    new_names = erase(new_names,'_xlsx');
    lastUpdate = datetime(1,'ConvertFrom','datenum');
    %load Signal file (if exist)
    
    if isfile(signal_history_file)
        opts = detectImportOptions(signal_history_file);
        in_table = readtable(signal_history_file,opts);
        signal_table = in_table(:,1:5);
        VarNames = signal_table.Properties.VariableNames;
        signal_table.(VarNames{1}).Format = 'dd-MMM-yyyy';
        DataStoring.signal_table = signal_table;
        last_vintage = signal_table.Vintage(end);
    else
        disp('***   WARNING   ***');
        disp('No Signal History excel file found');
        disp('a new signal history will be created');
        disp('starting from the rating file found in \Data');
    end
end

DataStoring.filenames = files_to_check';

if numel(new_files)>0 
    % get data
    for i = 1:numel(new_names)
        % read the table
        opts = detectImportOptions([data_dir,new_files{i}]);
        newTable = readtable([data_dir,new_files{i}],opts);
        
        %%% TO DO: CHOSE ONE OF THE TWO DATE %%%
        % read the date from the file name 
        index   = strfind(new_names{i}, '_');
        S       = new_names{i}((index(end))+1:end);
        StrDate = [S(1:4), '-', S(5:6), '-', S(7:8)];
        datefromname(i) = datetime(StrDate,'InputFormat','yyyy-MM-dd');
        
        % read the date from "last modification"
        FileInfo = dir([data_dir,new_files{i}]);
        TimeStamp(i) = datetime(FileInfo.date);
        TimeStamp.Format = 'dd-MMM-yyyy';
        
        % insert the date in the table
        n_row = size(newTable,1);
        newcol = repmat(datefromname(i),n_row,1);
        concTable = table(newcol,'VariableNames',{'Date'});
        newTable = [concTable, newTable];
        
        % store data in InputTables
        InputTables.(new_names{i}).date = datefromname(i);
        InputTables.(new_names{i}).date2 = TimeStamp(i);
        InputTables.(new_names{i}).rawTable = newTable;
        
        % store table in DataStoring
        DataStoring.DataTable = [DataStoring.DataTable; newTable];
        newlastUpdate = max(datefromname);
        DataStoring.lastUpdate = newlastUpdate;
        clear newTable;
    end
end


%% Data manipulation
%%%%% IMPORTANT: CALCULATIONS MUST BE PERFORMED ONLY IN CASE
%%%%% newlastUpdate > lastUpdate

if newlastUpdate>lastUpdate
    % to create a matrix with the relavant date (the last one and the use_previous_n_days
    % before.
    index_date = [];
    date_stored = unique(DataStoring.DataTable.Date);
    date_to_find = date_stored(end-use_previous_n_days+1:end,:);
    
    for i = 1:use_previous_n_days
        index_d= find(DataStoring.DataTable.Date == date_to_find(i));
        index_date = [index_date; index_d];
        clear index_d;
    end
    Table_to_analyze = DataStoring.DataTable(index_date,:);
    
    
    % get brockers names
    broker_names = {};
    
    names = Table_to_analyze.Properties.VariableNames;
    index_tgp = find(contains(names,'TGP'));
    index_eps = find(contains(names,'EPS'));
    index_rating = find(contains(names,'RATING'));
    min_names = min([index_tgp,index_eps,index_rating]);
    max_names = max([index_tgp,index_eps,index_rating]);
    broker_names = [broker_names, names(min_names:max_names)];
    
    broker_names = erase(broker_names, 'TGP');
    broker_names = erase(broker_names, 'EPS');
    broker_names = erase(broker_names, 'RATING');
    broker_names = erase(broker_names, '_');
    
    broker_names = unique(broker_names');
    
    % get company data
    company_name = {};
    
    company_name = unique(Table_to_analyze.Name);
    
    % read the EPS & RATING values for any name
    
    for i = 1:numel(company_name)
        
        c_names = Table_to_analyze.Name;
        index_cmp = find(contains(c_names,company_name{i}));
        
        for j = 1:numel(broker_names)
            b_names = Table_to_analyze.Properties.VariableNames;
            index_eps = find(contains(b_names,[broker_names{j},'_EPS']));
            index_rating = find(contains(b_names,[broker_names{j},'_RATING']));
            signal_eps = sum(Table_to_analyze{index_cmp,index_eps});
            signal_rating = sum(Table_to_analyze{index_cmp,index_rating});
            
            % contition on signal
            if signal_eps>=1 && signal_rating>=1
                condition = true;
                signal_to_wrt = 1;
            elseif signal_eps<=-1 && signal_rating<=-1
                condition = true;
                signal_to_wrt = -1;
            else
                condition = false;
            end
                
            if condition % verified
                
                %get ticker from bbg
                isin = unique(Table_to_analyze.ISIN(index_cmp));
                
                fields2download = {'dx895'};
                
                uparam.DataFromBBG = DataFromBBG;
                uparam.ticker = strcat(isin{1},' Equity');
                uparam.fields = fields2download;
                uparam.override_fields = [];
                uparam.BBG_SimultaneousData = [];
                uparam.FXE = false(1);
                
                U = Utilities(uparam);
                U.GetBBG_StaticData;
                
                ticker = cellstr([U.Output.BBG_getdata.dx895{1}, ' Equity']);
                
                % build the output table row to append to the output table.
                if exist('signal_table','var')
                    VarNames = signal_table.Properties.VariableNames;
                    row_to_add = table(newlastUpdate,ticker,broker_names(j),signal_to_wrt,last_vintage+1);
                    row_to_add.Properties.VariableNames = VarNames;
                    signal_table = [signal_table; row_to_add];
                else
                    last_vintage = 0;
                    row_to_add = table(newlastUpdate,'ticker',broker_names{j},signal,last_vintage+1);
                    signal_table = [signal_table; row_to_add];
                end
            end
            % end of condition
        end
    end
    DataStoring.signal_table = signal_table;
end
%% get tickers from figi
% % **** TEST ****
%
% fields2download = {'dx895'};
%
% uparam.DataFromBBG = DataFromBBG;
% uparam.ticker = ['GB0001367019',' Equity'];
% uparam.fields = fields2download;
% uparam.override_fields = [];
% uparam.BBG_SimultaneousData = [];
% uparam.FXE = false(1);
%
% U = Utilities(uparam);
% U.GetBBG_StaticData;
%
% ticker = [U.Output.BBG_getdata.dx895{1}, ' Equity'];
%
%

%% Saving data

save('DataStoring.mat', 'DataStoring');


