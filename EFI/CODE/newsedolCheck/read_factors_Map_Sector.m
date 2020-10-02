function [newSedol]=read_factors_Map_Sector(filename)
% Reads data from excel
%  the function finds the new sedols in the xlsx file (cfr lista
%  mappaSettoriIC2.xlsx e forwardPTF.xlsx)
%
% INPUT
% forwardPTF
%
% OUTPUT
% newSedol: list of new sedol
%  

%%
% vettore con le stringhe dei nomi dei file excel

sedolchkData=datastore('mappaSettoriICB2.xlsx','Sheet','all ID PIT VAL','Range','D:D');
sedolchktable=readall(sedolchkData);

sedolchk=sedolchktable{1:end,:};

importexcel=datastore(filename,'NumHeaderLines',5,'Range','A:IC');
factortable=readall(importexcel);

isinCell=factortable{1:end-1,3};
sedolCell=factortable{1:end-1,2}; %cellarray che contiene sedolchk che sono nella 2° colonna di forwardPTF
isinvector=isinCell;
sedolvector=sedolCell;


newSedol={};

new=1;

for j=1:length(sedolvector)
    if strcmp(sedolvector{j},'@NA')==1
       continue;
    end
    if strcmp(sedolchk,sedolvector{j})==0
       newSedol{new}=sedolvector{j};
       new=new+1;
       continue;
    end

end




end