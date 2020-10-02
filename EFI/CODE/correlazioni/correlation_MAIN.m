clc
clear
close all


userId = getenv('USERNAME');
addpath(['C:\Users\',userId,'\Desktop\EFI\CODE\input']);
outputpath= 'C:\Users\u369343\Desktop\EFI\CODE\output\correlazioni\';


%% data upload and flag definition
[mapSort]=createMapSort('sortCriteria.xlsx'); %map for sort criteria of each factor (ASC or DESC)
rfreduced=['SIMPLE_TOT_RET';'COMPOUND_TOT_RET';table2array(readtable('rf2supergroup.xlsx','Sheet','rf32'))];

%flag input
rolling=true;
sectorNeutral=0; %bysector %ATTENZIONE: RUNNARE INTERO CODICE CON 0 E POI CON 1
reduceRF_flag=[0 1];
rollinglag=24; %rollingwindow

%% read input from excel file

for f=1:length(reduceRF_flag)
    [sandwichData,cardCompaniesbyDate,ref_data_legend,rf]=readData('datasandwich_corr.xlsx',rfreduced,reduceRF_flag(f));
    ref_data_legend_time=datetime(datestr(datenum(num2str(ref_data_legend),'yyyymmdd')));
    
    %% create labels for matrices create a vector that contains all the possible combinations between factors
   
    count= 1;
    if reduceRF_flag(f)==1
        rf_legend=rfreduced;
    else
        rf_legend=rf(3:end)';
    end
    
    for i=1:length(rf_legend)
        for j=i:length(rf_legend)
            riskLegenda{count}=strcat(rf_legend{i},'\',rf_legend{j});
            count=count+1;
        end
    end
    riskLegendaT=cell2table(riskLegenda');
    riskLegendaT.Properties.VariableNames={'RF'};
    
    
    %% compute correlation
    if sectorNeutral==1 %by sector
        [corrMatrixSector,corrReturnSector]=factorcorrSN(sandwichData,0,ref_data_legend,rollinglag);
        if rolling==true
            [corrMatrixSectorRolling,corrReturnSector]=factorcorrSN(sandwichData,rolling,ref_data_legend,rollinglag);
            [historicalCorrSector]=historicalMatrixSector(corrMatrixSectorRolling);
            [valueCorrMatrix]=factorcorrSN(sandwichData,rolling,ref_data_legend,1);
            [historicalvalueCorrMatrix]=historicalMatrixSector(valueCorrMatrix);
        end
        %the last colum of datasandwich is taken because we need to divide sedol
        %by sectors
        [corrRankMatrixSector,corrRankReturn]=factorRankcorrSector(sandwichData(:,1:end),cardCompaniesbyDate,mapSort,rf_legend);
    else %over all (no sector layer)
        [corrMatrix]=factorcorr(sandwichData(:,2:end-1)); %all factors but the ref_date and ICB code
        if rolling==true
            [corrMatrixRoll,corrReturnRoll,startDate,endDate]=factorcorrRoll(sandwichData(:,1:end-1),ref_data_legend,rollinglag);
            [historicalCorr]=historicalmatrix(corrMatrixRoll);
        end
        [corrRankMatrix,corrRankReturn]=factorRankcorr(sandwichData(:,1:end-1),cardCompaniesbyDate,mapSort,rf_legend);
    end
    
    %% output over all
    x=[1;1000;2000;3000;4000;5000;6000;7000;8000;9000];
    firstcolum=array2table(rf_legend);
    
    if reduceRF_flag(f)==1
        reducedlabel='_32rf.xlsx';
    else
        reducedlabel='.xlsx';
    end
    
    if sectorNeutral==false
        
        filename = strcat(outputpath,'5_correlazioniOVERALL',reducedlabel);
       
        corrMatrix=array2table(corrMatrix);
        corrRankMatrix=array2table(corrRankMatrix);
        corrMatrix.Properties.VariableNames=rf_legend;
        corrRankMatrix.Properties.VariableNames=rf_legend;
        writetable([firstcolum corrMatrix],filename,'Sheet','5.1_corrMatrix')
        writetable([firstcolum corrRankMatrix],filename,'Sheet','5.2_corrRankMatrix')
        if  rolling==true
            historicalCorr=array2timetable(historicalCorr','RowTimes',ref_data_legend_time(rollinglag:end));
            historicalCorr.Properties.VariableNames=riskLegenda;
            writetimetable(historicalCorr,filename,'Sheet','5.3_historicalMatrix')
        end

    else % output by sector
        for i=1:10
            
            if rolling==true
                histMatrix=historicalCorrSector{i};
                histMatrix=array2timetable(histMatrix','RowTimes',ref_data_legend_time(rollinglag:end));
                histMatrix.Properties.VariableNames=riskLegenda;
                sheetname_hist=strcat('HistoricalCorr_ICB',num2str(x(i)));
                writetimetable( histMatrix,strcat(outputpath,'2_HistoricalCorrBySector',reducedlabel),'Sheet',sheetname_hist);
                
                histValueMatrix=historicalvalueCorrMatrix{i};
                histValueMatrix=array2timetable(histValueMatrix','RowTimes',ref_data_legend_time);
                histValueMatrix.Properties.VariableNames=riskLegenda;
                sheetname_hist=strcat('HistoricalCorr_ICB',num2str(x(i)));
                writetimetable(histValueMatrix,strcat(outputpath,'3_ValueCorrBySector&ByTime',reducedlabel),'Sheet',sheetname_hist);
            end
            
            corrMatrix=corrMatrixSector(x(i));
            corrMatrix=array2table(corrMatrix);
            corrMatrix.Properties.VariableNames=rf_legend;
            sheetname_corr=strcat('ValueCorr_ICB',num2str(x(i)));
            writetable([firstcolum corrMatrix],strcat(outputpath,'4_ValueCorrBySector',reducedlabel),'Sheet',sheetname_corr);
        end
        
        corrRankMatrixSector=array2table(corrRankMatrixSector);
        corrRankMatrixSector.Properties.VariableNames=rf_legend;
        writetable([firstcolum corrRankMatrixSector],strcat(outputpath,'1_RankCorrBySector',reducedlabel),'Sheet','corrRankMatrix')
 
    end
    clear riskLegenda
end