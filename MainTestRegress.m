
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

params.ExcelPath = 'C:\Users\u093799\Documents\GitHub\PrimoRepository\InputExcel\'; % 'C:\Users\u093799\Documents\MATLAB\AssetImport\InputExcel\';
params.BBGField = ['LAST_PRICE']; %to extract the historical price from bloomberg
params.StartDate = ['12/30/2005'];
params.EndDate = today;
params.Granularity = ['DAILY'];
params.IncludeAsset = true; % true; false; to include/exclude the Asset dates in the intersection
params.DataBBG = DataFromBBG;

TestU = Utilities(params);
TestU.CreateAssetDataSet;
finalOutput=TestU.Output;

OutputNames=fieldnames(finalOutput);

prm.inputdates = finalOutput.(OutputNames{1}).dates;
prm.inputarray = finalOutput.(OutputNames{1}).riskFactors;
prm.inputnames = finalOutput.(OutputNames{1}).riskFactorsTickers;

TestRegress = HFRegression(prm);
TestRegress.SimpleRegression;