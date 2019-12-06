%%% This mail is just to test all the functions needed to read and
%%% elaborate the input files for ARS_Trading_Tool 

clc; clear all; close all;

userId = getenv('USERNAME');
addpath(['C:\Users\' userId '\Documents\GitHub\Utilities']);

%%% INITIAL PARAMETERS %%%
data_dir = 'C:\Users\u093799\Documents\GitHub\PrimoRepository\Data\';
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
newlastUpdate = [];

if isfile('DataStoring.mat')
    load('Datastoring.mat');
    lastUpdate = DataStoring.lastUpdate;
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

% to create a matrix with the relavant date (the last one and the use_previous_n_days
% before.

% steps: 
% 1 read the column DataStoring.DataTable.Date
% 2 sort and unique 
% 3 get the last use_previous_n_days values
% filter the  DataStoring.DataTable in the way below
index(:,1) = find(DataStoring.DataTable.Date == '04-dec-2019');
index(:,2) = find(DataStoring.DataTable.Date == '03-dec-2019');
index = reshape(index,[],1);
myTable = DataStoring.DataTable(index,:);


% get brockers names
if numel(new_files)>0 
brokernames = {};

for i = 1:numel(new_names)
    names = InputTables.(new_names{i}).rawTable.Properties.VariableNames;
    index_tgp = find(~cellfun('isempty', strfind(names,'TGP')));
    index_eps = find(~cellfun('isempty', strfind(names,'EPS')));
    index_rating = find(~cellfun('isempty', strfind(names,'RATING')));
    min_names = min([index_tgp,index_eps,index_rating]);
    max_names = max([index_tgp,index_eps,index_rating]);
    brokernames = [brokernames, names(min_names:max_names)];
end

brokernames = erase(brokernames, 'TGP');
brokernames = erase(brokernames, 'EPS');
brokernames = erase(brokernames, 'RATING');
brokernames = erase(brokernames, '_');

brokernames = unique(brokernames');

% get company data
company_name = {};

for i = 1:numel(new_names)
    company_name{i} = InputTables.(new_names{i}).rawTable.Name;
end

end
% for i = 1:numel(company_names)


%% get tickers from figi 
% **** TEST ****

fields2download = {'dx895'};

uparam.DataFromBBG = DataFromBBG;
uparam.ticker = ['BBG000B9XRY4',' FIGI'];
uparam.fields = fields2download;
uparam.override_fields = [];
uparam.BBG_SimultaneousData = [];
uparam.FXE = false(1);

U = Utilities(uparam);
U.GetBBG_StaticData;

ticker = [U.Output.BBG_getdata.dx895{1}, ' Equity'];

    



%% Saving data

save('DataStoring.mat', 'DataStoring');


