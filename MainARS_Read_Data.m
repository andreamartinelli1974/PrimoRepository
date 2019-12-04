%%% This mail is just to test all the functions needed to read and
%%% elaborate the input files for ARS_Trading_Tool 

clc; clear all; close all;

data_dir = 'C:\Users\u093799\Documents\GitHub\PrimoRepository\Data\';
dir_content = dir([data_dir,'*.xlsx']);
files_to_check = {dir_content.name};
new_files = [];

old_data = [];
InputTables = [];

%% check for new input files and load them

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

%% Saving data

save('DataStoring.mat', 'DataStoring');


