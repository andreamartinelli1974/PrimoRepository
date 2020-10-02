function [factorMatrix,sedolCell,newSedol]=read_factors_Map_Sector(fileName)
% Reads data from excel
%  It reads factors of each asset for every date
%
% INPUT
% dateName  : vettore di stringhe --> la stringa i rappresenta la data di scarico
%                                     dell'iesimo scarico in formato yyyymmdd
% Nscarichi: number of all downloaded file excel. (171)
%
% OUTPUT
%
% cubodati: Map that associates at each data a matrix of all the RF
%            data
% sectorIndexMap: Map that links each sedol check to its ICB sector number
%  
% FUNCTION
% This function reads all the excel, saves them as matrix and create a Map
% that at each date returns the factorMatrix.


%%
% vettore con le stringhe dei nomi dei file excel

sedolchkData=datastore('mappaSettoriICB2_old.xlsx','Sheet','all ID PIT VAL','Range','D:D');
codiceICBData=datastore('mappaSettoriICB2_old.xlsx','Sheet','all ID PIT VAL','Range','Q:Q');
codiceICB2Data=datastore('mappaSettoriICB2_old.xlsx','Sheet','all ID PIT VAL','Range','U:U');
sedolchktable=readall(sedolchkData);
codiceICBtable=readall(codiceICBData);
codiceICB2table=readall(codiceICB2Data);

sedolchk=sedolchktable{1:end,:};
codiceICB=codiceICBtable{1:end,:};
codiceICB2=codiceICB2table{1:end,:};
sectorIndexMap=containers.Map(sedolchk,codiceICB);
sectorIndex2Map=containers.Map(sedolchk,codiceICB2);

%creo una mappa che ha come chiave le date e come valore la matrice dei
%fattori di rischio alla medesima data
%aggiungo i ritorni nelle PRIME due colonne
importexcel=datastore(fileName,'NumHeaderLines',5,'Range','A:IC');
factortable=readall(importexcel);

isinCell=factortable{1:end-1,3};
sedolCell=factortable{1:end-1,2}; %cellarray che contine sedolchk che sono nella 2 colonna
newSedol={};

factorMatrix=factortable{1:end-1,16:end}; %leggo tutti i risk factor

% voglio inserire come ultima colonna che indichi il codice ICB 2 livello: cerco sedol nella
% mappa Sectorcode i sedolchk ad ogni t.
count=1;
new=1;
factorMatrix(:,end+4)=zeros(length(sedolCell),1);
for j=1:length(sedolCell)
    if strcmp(sedolCell{j},'@NA')==1
       continue;
    end
    if strcmp(sectorIndex2Map.keys,sedolCell{j})==0
       newSedol{new}=sedolCell{j};
       new=new+1;
       continue;
    end
    factorMatrix(j,end)=sectorIndex2Map(sedolCell{j});
    if isnan(factorMatrix(j,end))==1
       sedolMancanti2{count}=sedolCell{j};
       count=count+1;
    end
end

% voglio inserire come ultima colonna che indichi il codice ICB: cerco sedol nella
% mappa Sectorcode i sedolchk ad ogni t.
count=1;
new=1;
for j=1:length(sedolCell)
      if strcmp(sedolCell{j},'@NA')==1
       continue;
      end
      
      if strcmp(sectorIndex2Map.keys,sedolCell{j})==0
       newSedol{new}=sedolCell{j};
       new=new+1;
       continue;
    end
    factorMatrix(j,end-1)=sectorIndexMap(sedolCell{j});
    if isnan(factorMatrix(j,end))==1
       sedolMancanti1{count}=sedolCell{j};
       count=count+1;
    end
end


%inserisco come ultima colonna il vettore PB/PCF con snodo sui finanziari 
factorMatrix(:,end-2)=factorMatrix(:,114); %inizializzo con il vettore PCF 
factorMatrix(:,end-3)=factorMatrix(:,114); %inizializzo con il vettore PCF 
index_bank=find(factorMatrix(:,end)==8350); %ICB second level for banks
factorMatrix(index_bank,end-2)=factorMatrix(index_bank,113);%per i finanziari sostituisco con il valore PB
index_fin=find(factorMatrix(:,end-1)==8000); %ICB second level for banks
factorMatrix(index_fin,end-3)=factorMatrix(index_fin,113);


end

