function [score,matrixWinnerRf]=scoreVector(winnerFactors,weigths,timesliceRank,formRftoColum)
for i=1:length(winnerFactors)
    indexes_rf(i)=formRftoColum(winnerFactors{i});%select columns that refears to winner risk factors
end
matrixWinnerRf=timesliceRank(:,indexes_rf);%matrix that contains only the chosen rf

%set up Nan Value as median in each rf
for i=1:size(matrixWinnerRf,2)
    factor_i=matrixWinnerRf(:,i);
    median_i= median(factor_i,'omitnan'); %calculate median without NaN
    index_nanRF=find(isnan(factor_i));
    matrixWinnerRf(index_nanRF,i)=median_i;
end
score=matrixWinnerRf*weigths';
end