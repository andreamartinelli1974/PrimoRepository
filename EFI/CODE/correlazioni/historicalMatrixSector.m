function [corrHistorical]= historicalMatrixSector (corrMatrixSector)
%INPUT: corrMatrixSector: map that given an ICB code return 148 correlation
%matrix (one for each rolling window)

%OUTPUT: corrHistorical: cell array whose elements are matrixes (one for each sector) that have
%as rows the historical behaviors of each correlation coef between pairs of
%rf 


load('legendaICB.mat')
for j=1:length(legendaIcb)
    code=legendaIcb(j);
    matriceArray=corrMatrixSector(code);
    corrHistoricalSeries=historicalmatrix (matriceArray);
    corrHistorical{j}=corrHistoricalSeries;
    
end
end