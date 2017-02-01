
clc;
clear all;
close all

DataFromBBG.save2disk = false(0); % btrue(1); % True to save all Bloomberg calls for future retrieval

DataFromBBG.folder = [cd,'\BloombergCallsData\'];
if DataFromBBG.save2disk 
    rmdir(DataFromBBG.folder(1:end-1),'s');
    mkdir(DataFromBBG.folder(1:end-1));
end
try
    javaaddpath('C:\blp\DAPI\blpapi3.jar')
    DataFromBBG.BBG_conn = blp;
    DataFromBBG.NOBBG = false(1); % True when Bloomberg is NOT available and to use previopusly saved data
catch ME
    DataFromBBG.BBG_conn = [];
    DataFromBBG.NOBBG = true(1);
end
 
pt = path;

addpath('C:\Users\u093799\Documents\GitHub\Utilities\', ...
    'C:\Users\u093799\Documents\GitHub\PrimoRepository');
