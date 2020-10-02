function [score]=scoreVector(weigths,timesliceRank)

%%INPUT: weigths: normalized weigths of each rf (IC coeff normalized)
% timeSliceRank: matrix that has as column ranks of each comapny fixed a rf
% OUTPUT: score: vector that associate at each company the linar
% combination between weights and ranks.


%substitute Nan values with median value for each rf
for i=1:size(timesliceRank,2)
    factor_i=timesliceRank(:,i);
    median_i= median(factor_i,'omitnan'); %calculate median without NaN
    index_nanRF=find(isnan(factor_i));
    timesliceRank(index_nanRF,i)=median_i;
end
score=timesliceRank*weigths'; %score of each company is the linear combination of its rank and the weigth of each rf
end