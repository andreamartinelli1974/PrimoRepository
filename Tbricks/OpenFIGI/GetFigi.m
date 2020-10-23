% GetFigi.m: this function executes the C# code compiled in
% FigiApiCsharpExample.exe, that reads a list of ISIN codes and get the
% corresponding FI

% INPUT (to C# exe): the input isin list must be in the CSV file isinList.csv, located
% in the subfolder \InputData of the working folder
% OUTPUT (of C# exe): the output json file is saved in the subfolder
% \OutputData of the working folder

close all;
clear all;
clc;

EXEpath = [cd,'\EXE\'];
EXEname = 'FigiApiCsharpExample.exe';
fullName = fullfile(EXEpath,EXEname);
system(fullName);

jsonInputFolder = [cd,'\OutputData\'];

json2beparsed = jsondecode(fileread([jsonInputFolder 'json.txt']));
output = parse_json(json2beparsed);


%
%
%     % result is an obj of .NET class System.String: need to be converted to
%     % Matlab 'char' to be used. The result is then converted in Matlab string to
%     % be processed further
%     output = string(char(result)); % OUTPUT (unfiltered)
%
%     % 1st: preprocessing: removing superfluous characters
%     filtered_1 = erase(output,{'"data":','"','{','}','[',']'})
%     % 2nd: parse tokens based on commas
%     expression = ','
%     [tokens]=regexp(filtered_1,expression,'split');
%
%     nTokens = numel(tokens); % # of identified tokens
%
%     done = false(1);
%     cnt = 0;
%     while ~done
%         cnt = cnt + 1;
%         if strcmp(extractBefore(tokens{cnt},":"),'figi')
%            done = true(1);
%            outFigi{k,1} = ISIN;
%            outFigi{k,2} = extractAfter(tokens{cnt},":");
%         end
%     end
% % end
%
% xlswrite('testOutput',outFigi);
%
% % OLD: to generater a key-value pairs map between the name of each output field
% % and its content (e.g. 'figi' and 'BBG883899992' )
% % mappings.(ISIN) = containers.Map;
%     % process single tokens to identify key/value pairs to feed a dictionary
% %     for k=1:nTokens
% %         key = extractBefore(tokens{k},":");
% %         value = extractAfter(tokens{k},":");
% %         mappings.(ISIN)(key) = value;
% %     end