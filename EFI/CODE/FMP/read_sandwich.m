function [cubodati,sedolMap, Nscarichi,rf,ref_date_legend]=read_sandwich(fileName,startpoint,savepath)
% Reads data from excel
%  It reads factors of each asset for every date
%
% INPUT
% datasandwich
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
%creo una mappa che ha come chiave le date e come valore la matrice dei
%fattori di rischio alla medesima data
%aggiungo i ritorni nelle PRIME due colonne
% importexcel e factortable e save sono comandi alternativi a load
importexcel=datastore(fileName);
factortable=readall(importexcel);
% load ([savepath,'factortable.mat']);
% in alternativa a save: tasto dx su tablename e save as
save ([savepath,'factortable.mat'],factortable);
rf=factortable.Properties.VariableNames(3:end);
risk32=readtable('rf2supergroup.xlsx','Sheet','rf32');
factortableT=factortable;

dateVector=factortableT.REF_DATE(1:end-1);
ref_date_legend=unique(dateVector(2:end-1));
for i=1:length(ref_date_legend)
    PositionDate=find(dateVector==ref_date_legend(i));
    startPosition=PositionDate(1);
    endPosition=PositionDate(end);
    sedolCell=factortableT.SEDOLCHK(startPosition:endPosition,1);
    factorMatrix=factortableT{startPosition:endPosition,3:end-1}; %leggo tutti i risk factor e ICB code
    if i==1
        cubodati=containers.Map(ref_date_legend(i),factorMatrix);
        sedolMap=containers.Map(ref_date_legend(i),{sedolCell});
    else
        cubodati(ref_date_legend(i))= factorMatrix;
        sedolMap(ref_date_legend(i))= {sedolCell};
    end
    
end
t_start=find(ref_date_legend==startpoint); %indica il numero di scarico da cui partire per l'analisi
if t_start~=1
    for i=1:t_start-1
        remove(cubodati,ref_date_legend(i));
        
    end
    ref_date_legend=ref_date_legend(t_start:end);
end

Nscarichi=length(ref_date_legend);
