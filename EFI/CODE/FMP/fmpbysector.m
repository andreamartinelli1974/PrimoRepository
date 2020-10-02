clear all
clc
close all
%% INPUT
Nscarichi =175;
dateName = datecompute("20050429","20191031",Nscarichi);
fileName = dateName + "_AllFactors.xlsx";
outlierCap=false; %fisso a true se voglio cappare i valori outlier. false altrimenti.
divisioneSettoriale=false; %fisso a true se voglio suddividere i finanziari dai non finanziari. false altrimenti
Npercentili=5; %percentili per ogni fattore


%% CREO CUBO DATI
% [cubodatiSector,sectorIndexMap,~,~,codeICB]=read_factors_Map_Sector(dateName,Nscarichi);
% save CubodatiSector.mat cubodatiSector
load('CubodatiSector.mat')
load('riskFactors')
riskFactors{end}='PB/PCF2';
riskFactors{end-1}='PB/PCF1';
%% creo Mappe per facilitare l'interpretazione dei dati
[mapSort,fromColumToRf,formRftoColum,rf,column,fromCodeToSector]=createMapsSector(Nscarichi,dateName,fileName);
save mapSort.mat mapSort
save fromColumToRf.mat fromColumToRf
save formRftoColum.mat formRftoColum
%save isinMap.mat sedolMap
%save sedolMap.mat sedolMap
%  load('isinMap');
%  load('sedolMap');
%  load('mapSort');
%  load('fromColumToRf');
%  load('formRftoColum');
%% gestione degli outlier e sottogruppi settoriali (per ora Finanziari o Non finanziari)
[cubodatiClean]= manage_outlier_Sector(cubodatiSector,dateName,Nscarichi,outlierCap,divisioneSettoriale,fileName);
%save CubodatiClean.mat cubodatiClean
%load('cubodatiClean');
[bmk]=readBmk('bmk.xlsx',dateName);

%% COSTRUZIONE PORTAFOGLI
factorMatrix=cubodatiClean(dateName(1,:));%mi serve per fissare il numero dei fattori

[row,col]=size(factorMatrix);
t_start=1; %indica il numero di scarico da cui partire per l'analisi

codeICB=unique(factorMatrix(:,end-1));
numerorf=length(rf);
countlegenda=1;
legenda=cell((numerorf-2)*10,1); %cell array che ha come elemneti il nome dei rf
count=1;
for code=1:length(codeICB)
    matrixretcol=1;
    returnSimple_puntual=zeros(Npercentili,Nscarichi+1); % ogni riga contiene i rendimenti puntuali del portafoglio costruito su un fattore
    returnCompound_puntual=zeros(Npercentili,Nscarichi+1); % ogni riga contiene i rendimenti puntuali del portafoglio costruito su un fattore
    returnSimple_cum=zeros(Npercentili,Nscarichi+1); % ogni riga contiene i rendimenti cumulati del portafoglio costruito su un fattore
    returnCompound_cum=zeros(Npercentili,Nscarichi+1); % ogni riga contiene i rendimenti cumulati del portafoglio costruito su un fattore
    capitalSimple = zeros(Npercentili,Nscarichi+1); % ogni riga contiene il capitale disponibile ad ogni data, del portafoglio costruito su un fattore
    capitalCompound = zeros(Npercentili,Nscarichi+1); % ogni riga contiene il capitale disponibile ad ogni data, del portafoglio costruito su un fattore
    
    capitalSimple(:,t_start) = 100; % capitale iniziale
    capitalCompound(:,t_start) = 100; % capitale iniziale
for j=3:numerorf % scorro i fattori (-2 perchè gli primi sono i ritorni e -1 il numero settoriale)
    i=column(j); %scorro il vettore che contiene il numero di colonne interessate
    riskf=fromColumToRf(i);
    if ~any(strcmp(riskFactors,riskf)) %select just the 65 winners factors
        continue;
    end
    legenda(countlegenda:countlegenda+9,1)={riskf(1:end)};
    countlegenda=countlegenda+10;
    sortFactor=mapSort(riskf);
    for t=t_start: cubodatiClean.Count %fisso la data,
        chiave=dateName(t,:);
        factorMatrix=cubodatiClean(chiave);
        factorNaN=false;
        
        sectorVector=find(factorMatrix(:,end-1)==codeICB(code));
        simpleReturn_t = factorMatrix(:,1);
        simpleReturn_tSector=simpleReturn_t(sectorVector);
        compReturn_t = factorMatrix(:,2);
        compReturn_tSector=compReturn_t(sectorVector);
        factor=factorMatrix(:,i); %fisso un fattore
        factorSector=factor(sectorVector);
        
        [factor_sorted, index] = sort(factorSector, sortFactor);
        
        compReturn_tSectorSorted = compReturn_tSector(index);
        simpleReturn_tSectorSorted = simpleReturn_tSector(index);
        
        MatrixCleaned = remove_nan([factor_sorted,compReturn_tSectorSorted,simpleReturn_tSectorSorted]);
        
        %controllo se ho troppi valori Nan
        factor_cleaned=MatrixCleaned(:,1);
        
        compReturn_t_Cleaned = MatrixCleaned(:,2);
        simpleReturn_t_Cleaned=MatrixCleaned(:,3);
        %card_portafogli = floor(length(factor_cleaned)/NtotalPercentili);
        
        % capital, ptf_return_L_puntual, ptf_return_L_cum:
        % matrici in cui la riga i è la serie dei dati dell'iesimo percentile
        % la colonna j è il dato di ogni percentile ad una determinata data
        % Matrix(i,j) : dato del percentile i alla data j
        
        [startVector,endVector,card,factorNan] = dividePercentile(factor_cleaned,Npercentili);
        if factorNan==true
            break;
        end
        for percentile =1:Npercentili
            % calcolo capitale del portafoglio disponibile alla data futura
          
            capitalSimple(percentile,t+1) = (capitalSimple(percentile,t)/card(percentile))*sum( (1+simpleReturn_t_Cleaned(startVector(percentile):endVector(percentile))) );
            capitalCompound(percentile,t+1) = (capitalCompound(percentile,t)/card(percentile))*sum( (1+compReturn_t_Cleaned(startVector(percentile):endVector(percentile))) );
            
            % rendimento puntuale
            returnSimple_puntual(percentile,t+1)=(capitalSimple(percentile,t+1)-capitalSimple(percentile,t))/capitalSimple(percentile,t);
            returnCompound_puntual(percentile,t+1)=(capitalCompound(percentile,t+1)-capitalCompound(percentile,t))/capitalCompound(percentile,t);
            
            % rendimento cumulato
            returnSimple_cum(percentile,t+1)=(capitalSimple(percentile,t+1)-capitalSimple(percentile,1))/capitalSimple(percentile,1);
            returnCompound_cum(percentile,t+1)=(capitalCompound(percentile,t+1)-capitalCompound(percentile,1))/capitalCompound(percentile,1);
        end
    end
    
    %% PORTAFOGLIO LONG(percentile numero indexLONG)-SHORT(percentile numero indexSHORT)
    
    %la funzione prende in input gli indici LONG SHORT e restituisce
    %una struct contentente tutte le informazioni LONG/SHORT e anche
    %del PTF LS
    if factorNaN==false
        indexLONG=1;
        indexSHORT=Npercentili;
        
        [resultsFactor] = ptfLongShort(indexLONG,indexSHORT,returnSimple_puntual, returnCompound_puntual, capitalCompound,returnCompound_cum,bmk);
        
        %costruisco una mappa che associa ad ogni colonna (i.e ad ogni fattore)
        %la struct dei risultati complessivi
        
        if j==3
            resultsMap= containers.Map(j,resultsFactor);
            matriceExcel=[resultsFactor.puntLong;resultsFactor.puntShort;resultsFactor.cumLong;resultsFactor.cumShort;resultsFactor.cumRet_LS;resultsFactor.puntRet_LS;...
            resultsFactor.puntRet_LBmktot;resultsFactor.cumRet_LBmktot;resultsFactor.puntRet_LBmknet;resultsFactor.cumRet_LBmknet];
            returnQuartile=returnCompound_cum;
        else
            
            resultsMap(j)=resultsFactor;
            matriceExcel=[matriceExcel;resultsFactor.puntLong;resultsFactor.puntShort;resultsFactor.cumLong;resultsFactor.cumShort;resultsFactor.cumRet_LS;resultsFactor.puntRet_LS;...
                resultsFactor.puntRet_LBmktot;resultsFactor.cumRet_LBmktot;resultsFactor.puntRet_LBmknet;resultsFactor.cumRet_LBmknet];
            returnQuartile=[returnQuartile;returnCompound_cum];
        end
        
        
        rfNoneliminati{matrixretcol}=riskf;
        matrixRet(:,matrixretcol)=[resultsFactor.puntRet_LS];
        [sortpuntret_LS, index]=sort(resultsFactor.puntRet_LS);
        for i=1:length(sortpuntret_LS)
            pos=find(sortpuntret_LS==resultsFactor.puntRet_LS(i));
            ranking(i)=pos;
        end
        rankMatrix(:,matrixretcol)=ranking;
        
        [annualizedRet(matrixretcol,1),annualizedVol(matrixretcol,1),SR_AR_AV(matrixretcol,1)]=annualizedMetrics(resultsFactor.puntLong);
        % IR
        extrareturn=(resultsFactor.puntLong-bmk.totRet'); 
        [~,~,IR(matrixretcol,1)]=annualizedMetrics(extrareturn);
        
        matrixretcol=matrixretcol+1;
        
        
    else
        
        indiceEliminati(count)=j;
        nanVector=nan(10,Nscarichi+1);
        
        resultsMap(j)=nanVector;
        matriceExcel=[matriceExcel;nanVector];
        rfeliminati{count}=riskf;
        count=count+1;
    end
    clear resultsFactor
end
    corrMatrix=corrcoef(matrixRet);
    corrRankMatrix=corrcoef(rankMatrix);
    
    filename = strcat('FMP_5Perc_',num2str(codeICB(code)),'ICB.xlsx');
    writematrix(matriceExcel,filename,'Sheet','5Perc_NOcap','Range','D3');
    writematrix(annualizedVol,filename,'Sheet','annualizedMetrics' ,'Range','D2')
    writematrix(annualizedRet,filename,'Sheet','annualizedMetrics' ,'Range','F2')
    writematrix(SR_AR_AV,filename,'Sheet','annualizedMetrics' ,'Range','H2')
    writematrix(IR,filename,'Sheet','annualizedMetrics' ,'Range','L2')
    
    filename = strcat('FMP_5Perc_',num2str(codeICB(code)),'ICB_correlation.xlsx');
    writematrix(matrixRet,filename,'Sheet','LSReturns_NOCapAll' ,'Range','D3')
    writematrix(corrMatrix,filename,'Sheet','corrMatrix' ,'Range','D3')
    writematrix(corrRankMatrix,filename,'Sheet','corrRankMatrix' ,'Range','D3')
end
%% Plot
corrMatrix=corrcoef(matrixRet);
corrRankMatrix=corrcoef(rankMatrix);
filename = 'returnsQuartile.xlsx';
writematrix(returnQuartile,filename,'Range','D2');

% filename = 'FMP_5Perc_SectorNeutral_weightBMK_2009_19.xlsx';
% writematrix(matriceExcel,filename,'Sheet','5Perc_NOcap','Range','D2')
% 
% filename = 'LSReturns_5Perc_SectorNeutral_weight_2009_19.xlsx';
% writematrix(matrixRet,filename,'Sheet','LSReturns_NOCapAll' ,'Range','D2')
% writematrix(corrMatrix,filename,'Sheet','corrMatrix' ,'Range','D2')
% writematrix(corrRankMatrix,filename,'Sheet','corrRankMatrix' ,'Range','D2')





