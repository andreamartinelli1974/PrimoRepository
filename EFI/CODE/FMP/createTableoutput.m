function [outputTableLO,outputTableLS,outputTableLB,outputTableMatriceExcel]=createTableoutput(rfNoneliminati,timeseries,matriceLO,matriceLS,matriceLB,matriceexcel,labelMatriceExcel,legenda,bmk)
%% this function takes as input the results matrices and returns tables to print out
    label=cell2table(rfNoneliminati');
    label.Properties.VariableNames={'riskFactor'};
    timelabel=cellstr(char(timeseries));
    
    matriceexcel=[matriceexcel;bmk.totRet';bmk.cumtotRet];
    TableMatriceExcel=array2table(matriceexcel);
    TableMatriceExcel.Properties.VariableNames=timelabel;
    labelmatrice = cell2table(labelMatriceExcel);
    labelmatrice(end+1:end+2,1)={'puntRetLO';'cumRetLO';};
    labelmatrice=[labelmatrice];

    legenda(end+1:end+2,1)={'BMK'};
    labelmatriceRF = cell2table(legenda);
    labelmatriceRF.Properties.VariableNames={'RF'};
    outputTableMatriceExcel= [labelmatriceRF labelmatrice TableMatriceExcel];
    
    
    tableLO = array2table([matriceLO;bmk.cumtotRet]);
    tableLO.Properties.VariableNames=timelabel;
    labelrf_LO=cell2table([rfNoneliminati';'BMK']);
    labelrf_LO.Properties.VariableNames={'RF'};
    labelLO=cell(1,size(labelrf_LO,1));
    labelLO(1,:)={'cumRetLO'};
    labelLOTable = cell2table(labelLO');
    labelLOTable.Properties.VariableNames={'TYPE_RETURN'};
   
    outputTableLO = [labelrf_LO labelLOTable tableLO];
    
    
    tableLS = array2table(matriceLS);
    tableLS.Properties.VariableNames=timelabel;
    labelLS=cell(1,size(label,1));
    labelLS(1,:)={'cumRetLS'};
    labelLSTable = cell2table(labelLS');
    labelLSTable.Properties.VariableNames={'TYPE_RETURN'};
    outputTableLS = [label labelLSTable tableLS];
    
    
    tableLB = array2table(matriceLB);
    tableLB.Properties.VariableNames=timelabel;
    labelLB=cell(1,size(label,1));
    labelLB(1,:)={'cumRetLB'};
    labelLBTable = cell2table(labelLB');
    labelLBTable.Properties.VariableNames={'TYPE_RETURN'};
    outputTableLB = [label labelLBTable tableLB];
end