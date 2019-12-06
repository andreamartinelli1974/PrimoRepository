%%% This mail is just to test all the functions needed to read and
%%% elaborate the input files for ARS_Trading_Tool 

clc; clear all; close all;

userId = getenv('USERNAME');
addpath(['C:\Users\' userId '\Documents\GitHub\Utilities']);

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

data_dir = 'C:\Users\u093799\Documents\GitHub\PrimoRepository\Data\';
dir_content = dir([data_dir,'*.xlsx']);
files_to_check = {dir_content.name};
new_files = [];

old_data = [];
InputTables = [];

if isfile('DataStoring.mat')
    load('Datastoring.mat');
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

DataStoring.filenames = files_to_check;

if numel(new_files)>0
    for i = 1:numel(new_files)
        opts = detectImportOptions([data_dir,new_files{i}]);
        InputTables.(new_names{i}).rawTable = readtable([data_dir,new_files{i}],opts);
        DataStoring.DataTable = [DataStoring.DataTable; InputTables.(new_names{i}).rawTable];
    end
    
    
    % get date
    for i = 1:numel(new_names)
        index   = strfind(new_names{i}, '_');
        S       = new_names{i}((index(end))+1:end);
        StrDate = [S(1:4), '-', S(5:6), '-', S(7:8)];
        InputTables.(new_names{i}).date = datetime(StrDate,'InputFormat','yyyy-MM-dd');
        FileInfo = dir([data_dir,new_files{i}]);
        TimeStamp = datetime(FileInfo.date);
        TimeStamp.Format = 'dd-MMM-yyyy';
        InputTables.(new_names{i}).date2 = TimeStamp;
    end
end

%% Data manipulation

% get brockers names

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

% get company names & figi
figi = {};
company_name = {};

for i = 1:numel(new_names)
    figi{i} = InputTables.(new_names{i}).rawTable.Symbol;
    company_name{i} = InputTables.(new_names{i}).rawTable.Name;
end

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


