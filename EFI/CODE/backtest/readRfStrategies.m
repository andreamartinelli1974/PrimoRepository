
function [strategieTable]=readRfStrategies(filename)
strategieData=datastore('strategie.xlsx','Sheet','STRATEGIE');
strategieTable=readall(strategieData);
end