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

%% test the function

% input parameters
b_params.data_dir = 'C:\Users\u093799\Documents\GitHub\PrimoRepository\Data\';
b_params.signal_history_file = 'Signals_traded_LIVE _Copy.xlsx';
b_params.use_previous_n_days = 2;
b_params.DataFromBBG = DataFromBBG;

% the function

data_table = read_broker_data(b_params);


