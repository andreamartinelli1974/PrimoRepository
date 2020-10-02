function [mapSort,fromColumToRf,formRftoColum,rf,column,fromCodeToSector,formSectortoCode]=createMapsSector(fileName)

%INPUT:
%Nscarichi: numero di scarichi totali
%dateName: date in formato stringa
%fileName: nome dei file excel da cui estrapolare le informazioni

%OUTPUT:
%fromColumToRf: una mappa che ha per chiave il numero di colonne della
%               matrice dei dati (fissata una data) e per valore il RF corrispondente
%formRftoColum: mappa che ha come chiavi il nome del RF e come valore il
%               relativo numero di colonne
%mapSort: mappa che ha come chiave il numero delle colonne delle matrice
%         e per valore il tipo di ordinamento.
%rf: vettore dei risk factor che stiamo considerando
%column: vettore i cui elementi rappresentano la posizione di uno specifico
%        rf nella matrice di scarico


%creo le mappe MapSort,fromColumToRf,formRftoColum
riskfactor= datastore(fileName,'Sheet','LEGENDA','NumHeaderLines',9,'Range','E:E');
rftable=readall(riskfactor);
rf=rftable{:,:};

riskfactortRank= datastore(fileName,'Sheet','LEGENDA','NumHeaderLines',9,'Range','G:G');
riskfactortRankTable=readall(riskfactortRank);
RFrank=riskfactortRankTable{:,:};

rfColumn= datastore(fileName,'Sheet','LEGENDA','NumHeaderLines',9,'Range','B:B');
rfColumnTable=readall(rfColumn);
column=rfColumnTable{:,:};

mapSort=containers.Map(rf,RFrank);
fromColumToRf=containers.Map(column,rf);
formRftoColum=containers.Map(rf,column);

sectorData= datastore(fileName,'Sheet','Settori','Range','B:B');
sectorTable=readall(sectorData);
sector=sectorTable{:,:};

idCodeData= datastore(fileName,'Sheet','Settori','Range','A:A');
idCodeTable=readall(idCodeData);
idCode=idCodeTable{:,:};

fromCodeToSector=containers.Map(idCode,sector);
formSectortoCode=containers.Map(sector,idCode);


end