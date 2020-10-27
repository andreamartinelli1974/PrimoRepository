%test getFigi

close all;
clear all;
clc;

addpath 'D:\Users\u093799\Documents\GitHub\PrimoRepository\Tbricks\OpenFIGI';

EXEpath = [cd,'\OpenFIGI\EXE\'];
EXEname = 'FigiApiCsharpExample.exe';
fullName = fullfile(EXEpath,EXEname);

isinInputFolder = [cd,'\InputData\'];
jsonInputFolder = [cd,'\OutputData\'];

% mainTable = readtable('mainPtfTable.xlsx');
% isin_list = unique(mainTable.ISIN);
% 
% if isin_list{1,1} == ""
%     isin_list(1) = [];
% end
% if isin_list{1,1} == "000000000000"
%     isin_list(1) = [];
% end
% 
% n_isin = numel(isin_list);
% if n_isin > 100
%     isin1 = isin_list(1:100);
% else
%     isin1 = isin_list;
% end
% 
% myList = cell2table(isin1(2:end),'VariableNames',isin1(1));
% writetable(myList,[isinInputFolder,'isinList.csv']);

system(fullName);

json2beparsed = jsondecode(fileread([jsonInputFolder 'json.txt']));
output = parse_json(json2beparsed);
errorlist = zeros(numel(output),1);

for i = 1:numel(output)
    if isfield(output{1,i},'error');
        errorlist(i) = 1;
    end
end

