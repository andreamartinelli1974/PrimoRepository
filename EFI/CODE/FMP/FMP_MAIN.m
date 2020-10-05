clear all
clc
close all

writeFlag = 0;

% **************** STRUCTURE TO ACCESS BLOOMBERG DATA *********************
DataFromBBG.save2disk = false(1); %false(1); % True to save all Bloomberg calls to disk for future retrieval
DataFromBBG.folder = [cd,'\BloombergCallsData\'];
 
if DataFromBBG.save2disk
    if exist('BloombergCallsData','dir')==7
        rmdir(DataFromBBG.folder(1:end-1),'s');
    end
    mkdir(DataFromBBG.folder(1:end-1));
end

try
    % javaaddpath('C:\blp\DAPI\blpapi3.jar');
    DataFromBBG.BBG_conn = blp; % throw error when Bloomberg is not installed
    pause(2);
    while isempty(DataFromBBG.BBG_conn) % ~isconnection(DataFromBBG.BBG_conn)
        pause(2);
    end
    
    DataFromBBG.NOBBG = false(1); % True when Bloomberg is NOT available and to use previopusly saved data
    
catch ME
    % dlgTitle = 'BBG ALERT';
    % dlgQuest = 'BLOOMBER NOT AVAILABLE! Do you with to continue?';
    % answer = questdlg(dlgQuest,dlgTitle,'yes','no','no');
    % if strcmp(answer,'no')
    %     return
    % end
    if isdeployed
    RunMsg = msgbox('Connection to Bloomberg not available', ...
        'Deployed code execution');
    end
    DataFromBBG.BBG_conn = [];
    DataFromBBG.NOBBG = true(1); % if true (on machines with no BBG terminal), data are recovered from previously saved files (.save2disk option above)
end
% *************************************************************************


%% Factor Mimicking PTF
%  This code is used to create the historical time series of all the
%  risk-factors from Apr 2005. taking as input the updated datasandwich, the function retuns 4 output files:
%  1.FMP: that reports LongOnly, ShortOnly, LngShort, LongBmk returns for
%         each rf.
%  2.FMP_returns_perFrattile_LO: that reports LO historical returns for
%                                  each fractile of each rf;
%  3/4. FMP_LSReturns_correlations(_32rf): that report corr matrix and rank
%                                          corr matrix between LS returns


userId = lower(getenv('USERNAME'));

if strcmp(userId,'u093799')
    dsk = 'D:\';
else
    dsk = 'C:\';
end

%%%%%%*********** TO DO: UPDATE THE PATH IN FINAL VERSION ***********%%%%%%

addpath([dsk,'Users\' userId '\Documents\GitHub\Utilities\'], ...
        ['X:\SalaOp\EquityPTF\Dashboard\outRiskExcel\']);

if strcmp(userId,'u093799')
    addpath(['D:\Users\',userId,'\Documents\GitHub\PrimoRepository\EFI\CODE\input\']);
    addpath(['D:\Users\',userId,'\Documents\GitHub\PrimoRepository\EFI\CODE\input\anagrafiche']);
    
    inputpath  = ['D:\Users\',userId,'\Documents\GitHub\PrimoRepository\EFI\CODE\input\'];
    outputpath = ['D:\Users\',userId,'\Documents\GitHub\PrimoRepository\EFI\CODE\output\FMP\'];
    
else
    addpath(['C:\Users\',userId,'\Desktop\EFI\CODE\input']);
    addpath(['C:\Users\',userId,'\Desktop\EFI\CODE\input\anagrafiche']);
    
    inputpath  = ['C:\Users\',userId,'\Desktop\EFI\CODE\input\'];
    outputpath = ['C:\Users\',userId,'\Desktop\EFI\CODE\output\FMP\'];
end



%% INPUT
outlierCap=false; %fisso a true se voglio cappare i valori outlier. false altrimenti.
divisioneSettoriale=false; %fisso a true se voglio suddividere i finanziari dai non finanziari. false altrimenti
Npercentili=5;
startpoint=20050429;

%% CREO CUBO DATI
[cubodatiSector,sedolchkMap,Nscarichi,riskFactors,ref_date_legend]=read_sandwich('datasandwich.xlsx',startpoint);
%[cubodatiSector,sedolchkMap,Nscarichi,riskFactors,ref_date_legend]=read_sandwich('US_portfolio_screen (Monthly update).xlsx',startpoint);

%% CREO TIME SERIES PARTENDO DALLA PRIMA DATA (APRILE 2005)

startdate=datetime(datestr(datenum(num2str(ref_date_legend(1)),'yyyymmdd')));
enddate=datetime(datestr(datenum(num2str(ref_date_legend(end)),'yyyymmdd')));
% enddate=dateshift(datetime(datestr(datenum(num2str(ref_date_legend(end)),'yyyymmdd'))),'end','month','next');
dateseries=busdays(startdate,enddate,'monthly');
timeseries=datetime(busdays(startdate,enddate,'monthly'));
timeseries_str=datestr(busdays(startdate,enddate,'monthly'));

%% creo Mappe per facilitare l'interpretazione dei dati
[mapSort,fromColumToRf,formRftoColum,rf,column,fromCodeToSector]=createMapsSector('LEGENDARISKF.xlsx');


%% gestione degli outlier e sottogruppi settoriali (per ora Finanziari o Non finanziari)
[cubodatiClean,sedolchkMapClean]= manage_outlier_Sector(cubodatiSector,Nscarichi,outlierCap,sedolchkMap);
[bmk]=readBmk('bmk.xlsx',ref_date_legend);
[rf32Legend]=readtable('rf2supergroup.xlsx','Sheet','rf32');
clear cubodatiSector

%% Inizializzazione variabili
returnSimple_puntual=zeros(Npercentili,size(timeseries,1)); % ogni riga contiene i rendimenti puntuali del portafoglio costruito su un fattore
returnCompound_puntual=zeros(Npercentili,size(timeseries,1)); % ogni riga contiene i rendimenti puntuali del portafoglio costruito su un fattore
returnSimple_cum=zeros(Npercentili,size(timeseries,1)); % ogni riga contiene i rendimenti cumulati del portafoglio costruito su un fattore
returnCompound_cum=zeros(Npercentili,size(timeseries,1)); % ogni riga contiene i rendimenti cumulati del portafoglio costruito su un fattore
capitalSimple = zeros(Npercentili,size(timeseries,1)); % ogni riga contiene il capitale disponibile ad ogni data, del portafoglio costruito su un fattore

capitalCompound = zeros(Npercentili,Nscarichi+1); % ogni riga contiene il capitale disponibile ad ogni data, del portafoglio costruito su un fattore

%% COSTRUZIONE TABELLE da Fattore a Stile per ogni sedol
lastSedols=sedolchkMapClean(ref_date_legend(end));
lastSedolsList = lastSedols{1};
AllStocksFactorRankingTable = [array2table(lastSedolsList),array2table(nan(numel(lastSedolsList),numel(riskFactors)-4))];
AllStocksFactorRankingTable.Properties.VariableNames = [{'sedol'},riskFactors(3:end-2)];
AllStocksFactorRankingTable_Digital = AllStocksFactorRankingTable;

Factor2Style = readtable('rf2supergroup.xlsx','Sheet','Foglio1');
Styles = unique(Factor2Style.SUPER_GROUP);
AllStocksStyle = [array2table(lastSedolsList),array2table(zeros(numel(lastSedolsList),numel(Styles)))];
AllStocksStyle.Properties.VariableNames = ['sedol';Styles];


% check numero fattori
if size(Factor2Style,1) ~= numel(riskFactors)-4
    error('il numero di fattori in Factor2Styles.xlsx non coincide con i fattori nel datasandwich');
end

%% COSTRUZIONE PORTAFOGLI


capitalSimple(:,1) = 100; % capitale iniziale
capitalCompound(:,1) = 100; % capitale iniziale
labelRow={'puntRetLO';'puntRetSO';'cumRetLO';'cumRetSO';'cumRetLS_Net';...
    'puntRetLS_Net';'puntRetLB_Net';'cumRetLB_Net'};

numerorf=length(riskFactors);
countlegenda=1;

count=1;
matrixretcol=1;
matrixretcol32=1;
newTable=1;
page=1;
for j=3:numerorf-2 % scorro i fattori (parto da 3 perchè primi due sono ritorni e tolgo le ultime 2 colonne che contengono icb code)
    
    riskf=riskFactors{j}; %fisso risk factor
    sortFactor=mapSort(riskf); %criterio di ordinamento ASC or DESC
    for t=1: cubodatiClean.Count %fisso la data,
        
        ref_date=ref_date_legend(t);
        factorMatrix=cubodatiClean(ref_date); %rf and returns matrix at date "ref_date"
        sedolchks=sedolchkMapClean(ref_date); %companies in the index at "ref_date"
        sedolchk=sedolchks{1};
        factorNaN=false;
        simpleReturn_t = factorMatrix(:,1);
        compReturn_t = factorMatrix(:,2);
        sectorVector=factorMatrix(:,end);
        factor=factorMatrix(:,j); %extract j-factor from factorMatrix
        
        [MatrixCleaned,nan_row] = remove_nan([factor,compReturn_t,simpleReturn_t,sectorVector]);
        sedolchk(nan_row)=[];
        %check if the j-riskfactor has more the 20% of missing data
        factor_cleaned=MatrixCleaned(:,1);
        
        valoreSoglia=round(length(factor)/100)*20;
        if length(factor_cleaned)<(length(factor)-valoreSoglia)
            factorNaN=true;
            break;
        end
        
        %CellArray that has as elements FMP sector neutral. i.e. the first
        %element is a portfolio composed by the top companies of each sector.
        vectorKeys = keys(fromCodeToSector);
        [cellarraySettoriale,cardMatrix,costituents]=sectorNeutralPortfolio_weight(MatrixCleaned, vectorKeys,sortFactor,Npercentili,sedolchk);
        
        costSize = 0; % per controllare che il numero di costituents sia uguale al numero di sedols
        for percentile =1:Npercentili
            matricepercettile=cellarraySettoriale{percentile};
            [righe,colonne]=size(matricepercettile); %il numero di righe mi indica la cardinalità delportafoglio
            
            if t~=cubodatiClean.Count
                %  serie storica rendimento puntuale per ogni percentile
                returnSimple_puntual(percentile,t+1)=((1+matricepercettile(:,2))'*cardMatrix{percentile})-1;
                returnCompound_puntual(percentile,t+1)=((1+matricepercettile(:,3))'*cardMatrix{percentile})-1;
            else
                
                for i=1:numel(costituents{percentile})
                    idx = find(strcmp(AllStocksFactorRankingTable.sedol, costituents{percentile}(i)));
                    
                    switch percentile
                        case 1
                            AllStocksFactorRankingTable_Digital.(riskFactors{j})(idx) = 1;
                        case 2
                            AllStocksFactorRankingTable_Digital.(riskFactors{j})(idx) = 1;
                        case Npercentili -1
                            AllStocksFactorRankingTable_Digital.(riskFactors{j})(idx) = -1;
                        case Npercentili
                            AllStocksFactorRankingTable_Digital.(riskFactors{j})(idx) = -1;
                        otherwise
                            AllStocksFactorRankingTable_Digital.(riskFactors{j})(idx) = 0;
                    end
                end
                costSize = costSize + numel(costituents{percentile});
            end
            
            %%   salva composizione dei portafogli fattoriali
            
                  if percentile==1 && t==1 && newTable==1
                            costituentsTable=table( repmat({timeseries(t,:)},length(costituents{percentile}),1),...
                                repmat({riskf},length(costituents{percentile}),1),...
                                repmat(percentile,length(costituents{percentile}),1),...
                                costituents{percentile},cardMatrix{percentile});
                            newTable=0;
                        elseif percentile==5 || percentile==1
                            costituentsTable =[costituentsTable;table(repmat({timeseries(t,:)},length(costituents{percentile}),1),...
                                repmat({riskf},length(costituents{percentile}),1),...
                                repmat(percentile,length(costituents{percentile}),1),...
                                costituents{percentile},cardMatrix{percentile})];
            
                        end
            
        end
        if t==cubodatiClean.Count
            AllStocksFactorRankingTable.(riskFactors{j})= factor;
        end
    end
    %%      stampa composizione dei portafogli fattoriali
    %  we need to print the output table bit by bit to not overstep the excel row's limits
    % NOTA BENE: writeflag aggiunto da AM per saltare questa parte: va
    % tolto nella versione definitiva
        if writeFlag ==1 && (size(costituentsTable,1)> 900000 || j==numerorf-2)
            filename =strcat(outputpath,'FMPComponents.xlsx');
            costituentsTable.Properties.VariableNames={'Date' 'RiskFactor', 'Percentile', 'Components', 'Weigths'};
            writetable(costituentsTable,filename,'Sheet',strcat('FMPComponents',num2str(page))) ;
            page=page+1;
            clear costituentsTable
            newTable=1;
        end
    %% PORTAFOGLIO LONG(percentile numero indexLONG)-SHORT(percentile numero indexSHORT)
    
    if factorNaN==false
        indexLONG=1;
        indexSHORT=Npercentili;
        puntret_LO=returnCompound_puntual(indexLONG,:);
        puntret_SO=-returnSimple_puntual(indexSHORT,:); %negative ret of the last percentile
        initialcapital=100;
        
        %Default sets legWeigth=1 and NetExposure for LS ptf
        legWeigth=1;
        isGrossEx=false;
        
        %conctruction of LongOnly/ShortOnly/LongShort/LongBmk returns
        [resultsFactor]=LongShort(puntret_LO,puntret_SO,bmk,initialcapital, legWeigth,isGrossEx);
        
        %matrix that contains cum return LO for each percentile
        [returnCompound_cum]=calculateCumRet_LO(returnCompound_puntual,initialcapital);
        
        if j==3
            %matriceExcel:for each risk factor 14 returns timeseries are
            %printed on an excel file in "FMP.xlsx"
            matriceExcel=[puntret_LO;puntret_SO;resultsFactor.cumret_LO;resultsFactor.cumret_SO;resultsFactor.cumret_LS;resultsFactor.puntret_LS;...
                resultsFactor.puntret_LB;resultsFactor.cumret_LB];
            
            
            %returnQuartileCum/returnQuartilePunt: matrices that contain
            %cum and puntual returns for each percentile
            returnQuartilePunt=returnCompound_puntual;
            returnQuartileCum=returnCompound_cum;
            
            
            matriceLO=resultsFactor.cumret_LO;
            matriceLS=resultsFactor.cumret_LS;
            matriceLB=resultsFactor.cumret_LB;
            labelMatriceExcel=labelRow;
            legenda=repmat({riskf},length(labelRow),1); %cell array che ha come elemneti il nome dei rf
            
        else
            
            matriceExcel=[matriceExcel;puntret_LO;puntret_SO;resultsFactor.cumret_LO;resultsFactor.cumret_SO;resultsFactor.cumret_LS;resultsFactor.puntret_LS;...
                resultsFactor.puntret_LB;resultsFactor.cumret_LB];
            returnQuartilePunt=[returnQuartilePunt;returnSimple_puntual];
            returnQuartileCum=[returnQuartileCum;returnCompound_cum];
            
            matriceLO=[matriceLO;resultsFactor.cumret_LO];
            matriceLS=[matriceLS;resultsFactor.cumret_LS];
            matriceLB=[matriceLB;resultsFactor.cumret_LB];
            labelMatriceExcel=[labelMatriceExcel;labelRow];
            legenda=[legenda;repmat({riskf},length(labelRow),1)];
            
        end
        %last value of LO LS puntual return for each risk factor
        lastLOreturn(matrixretcol)=puntret_LO(end);
        lastLSreturn(matrixretcol)=resultsFactor.puntret_LS(end);
        
        
        rfNoneliminati{matrixretcol}=riskf;
        matrixRet(:,matrixretcol)=[resultsFactor.puntret_LS];
        [sortpuntret_LS, index]=sort(resultsFactor.puntret_LS);
        for i=1:length(sortpuntret_LS)
            pos=find(sortpuntret_LS==resultsFactor.puntret_LS(i));
            ranking(i)=pos;
        end
        rankMatrix(:,matrixretcol)=ranking;
        
        
        
        if ismember(riskf,table2array(rf32Legend))
            matrixRet32(:,matrixretcol32)=[resultsFactor.puntret_LS];
            rankMatrix32(:,matrixretcol32)=ranking;
            matrixretcol32=matrixretcol32+1;
        end
        
        
        %calculate annualized metrics for LO/LS/LB timeseries
        [annualizedRetLO(matrixretcol,1),annualizedVolLO(matrixretcol,1),std_LO(matrixretcol,1),meanLO(matrixretcol,1),medianLO(matrixretcol,1),SR_AR_AV_LO(matrixretcol,1)]=annualizedMetrics(puntret_LO);
        [annualizedRetLS(matrixretcol,1),annualizedVolLS(matrixretcol,1),std_LS(matrixretcol,1),meanLS(matrixretcol,1),medianLS(matrixretcol,1),SR_AR_AV_LS(matrixretcol,1)]=annualizedMetrics(resultsFactor.puntret_LS);
        [annualizedRetLB(matrixretcol,1),annualizedVolLB(matrixretcol,1),std_LB(matrixretcol,1),meanLB(matrixretcol,1),medianLB(matrixretcol,1),SR_AR_AV_LB(matrixretcol,1)]=annualizedMetrics(resultsFactor.puntret_LB);
        % IR
        extrareturn=(puntret_LO-bmk.totRet');
        [~,~,IR(matrixretcol,1)]=annualizedMetrics(extrareturn);
        
        matrixretcol=matrixretcol+1;
    else
        
        rfeliminati{count}=riskf;
        count=count+1;
    end
    clear cellarraySettoriale
end
clear cubodatiClean
%% Get the stock style 
[snum,fnum] = size(AllStocksFactorRankingTable_Digital);
myfactornames = AllStocksFactorRankingTable_Digital.Properties.VariableNames;
for i = 1:snum % per ogni sedol
    
    for j = 1:numel(Styles) % seleziono lo stile
        % trovo i fattori che lo compongono e carico i pesi per ogni
        % fattore
        sidx = find(strcmp(Factor2Style.SUPER_GROUP,Styles{j}));
        
        stylefactors = Factor2Style.RF(sidx);
        fweight = Factor2Style.weight(sidx);
        
        WeightedStyleRank = NaN(size(fweight));
        StyleRank = NaN(size(fweight));
        
        for k = 1:numel(stylefactors) % per ogni fattore che compone lo stile
            % trovo il ranking assegnato al sedol
            findex = find(strcmp(myfactornames,stylefactors{k}));
            ranking = AllStocksFactorRankingTable_Digital{i,findex};
            
            if ~isnan(ranking)
                WeightedStyleRank(k) = fweight(k)*ranking;
                StyleRank(k) = ranking;
            end
        end
        
        % crea medie mode e mediane sui 58 fattori (unweighted)
        
        if sum(isnan(StyleRank))==numel(StyleRank)
            clear StyleRank_58_1;
            StyleRank = 0;
        end
        StyleRank = StyleRank(~isnan(StyleRank)); % elimino i NaN
        media_style = mean(StyleRank); % calcolo la media
        median_style = median(StyleRank); % calcolo la mediana
        if abs(median_style) == 0.5
            median_style = sign(median_style);
        end
        moda_style = mode(StyleRank); % calcolo la moda
        AllStocksStyle{i,j+1} = median_style;
        %AllStocksStyle{i,j+numel(Styles)+1} = median_style;
        %AllStocksStyle{i,j+2*numel(Styles)+1} = moda_style;
        
    end
end
%% get data from bbg
sedollist = strcat('/sedol1/',AllStocksStyle.sedol);

N = size(sedollist,1);
% get the fields: EQ_FUND_CODE LONG_COMP_NAME ICB_INDUSTRY_NAME ICB_SECTOR_NAME CUR_MKT_CAP 
uparams.fields = {'DX895','DS520','DX941','DX945','RR902'};
uparams.override_fields = [];
uparams.history_start_date = today()-20;
uparams.history_end_date = today();
uparams.DataFromBBG = DataFromBBG;


for k=1:N
    uparams.ticker = sedollist{k,1};
    uparams.granularity = 'daily';
    U = Utilities(uparams);
    U.GetBBG_StaticData;
    
    % EQ_FUND_CODE
    if isempty(U.Output.BBG_getdata.DX895{:})
        sedollist{k,2} = 'N/A';
    else
        sedollist{k,2} = strcat(U.Output.BBG_getdata.DX895{:},' Equity');
    end  
    % LONG_COMP_NAME
    if isempty(U.Output.BBG_getdata.DS520{:})
        sedollist{k,3} = 'N/A';
    else
        sedollist{k,3} = U.Output.BBG_getdata.DS520{:};
    end 
    % ICB_INDUSTRY_NAME
    if isempty(U.Output.BBG_getdata.DX941{:})
        sedollist{k,4} = 'N/A';
    else
        sedollist{k,4} = U.Output.BBG_getdata.DX941{:};
    end 
    % ICB_SECTOR_NAME
    if isempty(U.Output.BBG_getdata.DX945{:})
        sedollist{k,5} = 'N/A';
    else
        sedollist{k,5} = U.Output.BBG_getdata.DX945{:};
    end 
    % CUR_MKT_CAP
    if isempty(U.Output.BBG_getdata.RR902)
        sedollist{k,6} = 'N/A';
    else
        sedollist{k,6} = U.Output.BBG_getdata.RR902;
    end 
end
InfoTable = array2table(sedollist(:,2:end));
InfoTable.Properties.VariableNames = {'EQ_FUND_CODE' 'LONG_COMP_NAME' 'ICB_INDUSTRY_NAME' 'ICB_SECTOR_NAME' 'CUR_MKT_CAP'};

date = array2table(repmat(ref_date_legend(end),size(sedollist,1),1));
date.Properties.VariableNames = {'RF'};

% rearrange AllStocksFactorRankingTable column
TableColumnNames =['sedol'; Factor2Style.RF];
AllStocksFactorRankingTable = AllStocksFactorRankingTable(:,TableColumnNames);

OutForDashBoard = [date,InfoTable,AllStocksFactorRankingTable(:,2:end),AllStocksStyle(:,2:end)];
OutForDashBoard = sortrows(OutForDashBoard,[4 -6]);

%% tables for output
writetable(AllStocksFactorRankingTable,[outputpath,'AllStocksFactorRanking_',num2str(ref_date_legend(end)),'.xlsx']);
writetable(AllStocksFactorRankingTable_Digital,[outputpath,'AllStocksFactorRankingTable_Digital_',num2str(ref_date_legend(end)),'.xlsx']);
writetable(AllStocksStyle,[outputpath,'AllStocksStyle_',num2str(ref_date_legend(end)),'.xlsx']);
writetable(OutForDashBoard,[outputpath,'factor&style_',num2str(ref_date_legend(end)),'.xlsx']);

[outputTableLO,outputTableLS,outputTableLB,outputTableMatriceExcel]=createTableoutput(rfNoneliminati,timeseries_str,matriceLO,matriceLS,matriceLB,matriceExcel,labelMatriceExcel,legenda,bmk);

AnnualizedMetricsTable=array2table([outputTableLO{1:end-1,end},annualizedRetLO,annualizedVolLO,std_LO,meanLO,medianLO,SR_AR_AV_LO,...
    outputTableLS{:,end},annualizedRetLS,annualizedVolLS,std_LS,meanLS,medianLS,SR_AR_AV_LS,...
    outputTableLB{:,end},annualizedRetLB,annualizedVolLB,std_LB,meanLB,medianLB,SR_AR_AV_LB]);
AnnualizedMetricsTable.Properties.VariableNames={'LO_CUMreturn_last_date','annualizedRetLO','annualizedVolLO','std_LO','meanLO','medianLO','SR_AR_AV_LO',...
    'LS_CUMreturn_last_date','annualizedRetLS','annualizedVolLS','std_LS','meanLS','medianLS','SR_AR_AV_LS',...
    'LB_CUMreturn_last_date','annualizedRetLB','annualizedVolLB','std_LB','meanLB','medianLB','SR_AR_AV_LB'};

[annualizedRetBMK,annualizedVolBMK,std_BMK,meanBMK,medianBMK,SR_AR_AV_BMK]=annualizedMetrics(bmk.totRet');
BMKMatrics={'BMK',bmk.cumtotRet(end), annualizedRetBMK,annualizedVolBMK,std_BMK,meanBMK,medianBMK,SR_AR_AV_BMK};



outputAnnualizedMetrics=[outputTableLO(1:end-1,1) AnnualizedMetricsTable];
filename=strcat(outputpath,'FMP.xlsx');
writetable(outputTableMatriceExcel,filename,'Sheet','5Perc_Nocap_SNW_ALLHISTORY','Range','B1') ;
writetable(outputTableLO,filename,'Sheet','CUM_LONGONLY_DATA','Range','B1') ;
writetable(outputTableLS,filename,'Sheet','CUM_LONGSHORT_DATA','Range','B1') ;
writetable(outputTableLB,filename,'Sheet','CUM_LONGBMK_DATA','Range','B1') ;
writetable(outputAnnualizedMetrics,filename,'Sheet','FMP&BMK_STAT','Range','A1') ;
writecell(BMKMatrics,filename,'Sheet','FMP&BMK_STAT','Range',strcat('A', num2str(size(outputAnnualizedMetrics,1)+2)));

writetable(outputTableMatriceExcel,[inputpath,'FMP.xlsx'],'Sheet','5Perc_Nocap_SNW_ALLHISTORY','Range','B1') ;
%%

filename = strcat(outputpath,'FMP_returns_perFrattile_LO.xlsx');
x=unique(legenda,'Stable');
legendaReturn=repmat(x(1),5,1);
for i=2:length(x)
    legendaReturn=[legendaReturn;repmat(x(i),5,1)];
end
numPerc=repmat((1:5)',length(x),1);
T=[cell2table(legendaReturn) array2table(numPerc)];
T.Properties.VariableNames={'RiskFactor', 'Percentile'};
returnQuartileCumTable=array2table(returnQuartileCum);
returnQuartilePuntTable=array2table(returnQuartilePunt);
returnQuartileCumTable.Properties.VariableNames=cellstr(char(timeseries));
returnQuartilePuntTable.Properties.VariableNames=cellstr(char(timeseries));
writetable([T returnQuartileCumTable],filename,'Sheet', 'CumReturn');
writetable([T returnQuartilePuntTable],filename,'Sheet', 'PuntReturn');
%%
filename = strcat(outputpath,'FMP_LSReturns_correlations.xlsx');
tableRetLS= array2timetable(matrixRet,'RowTimes',dateseries);
tableRetLS.Properties.VariableNames=x;
firstcolum=cell2table(x);

corrMatrix=array2table(corrcoef(matrixRet));
corrRankMatrix=array2table(corrcoef(rankMatrix));
corrMatrix.Properties.VariableNames=x;
corrRankMatrix.Properties.VariableNames=x;

writetimetable(tableRetLS,filename,'Sheet','LSReturns_NOCapAll')
writetable([firstcolum corrMatrix],filename,'Sheet','corrMatrix')
writetable([firstcolum corrRankMatrix],filename,'Sheet','corrRankMatrix')

%% just with 32 rf
filename = strcat(outputpath,'FMP_LSReturns_correlations_32rf.xlsx');
tableRetLS32= array2timetable(matrixRet32,'RowTimes',dateseries);
tableRetLS32.Properties.VariableNames=table2array(rf32Legend);
firstcolum=rf32Legend;

corrMatrix=array2table(corrcoef(matrixRet32));
corrRankMatrix=array2table(corrcoef(rankMatrix32));
corrMatrix.Properties.VariableNames=table2array(rf32Legend);
corrRankMatrix.Properties.VariableNames=table2array(rf32Legend);

writetimetable(tableRetLS32,filename,'Sheet','LSReturns')
writetable([firstcolum corrMatrix],filename,'Sheet','corrMatrix')
writetable([firstcolum corrRankMatrix],filename,'Sheet','corrRankMatrix')