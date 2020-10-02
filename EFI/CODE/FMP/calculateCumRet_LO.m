function [returnCompound_cum]=calculateCumRet_LO(returnCompound_puntual,LOcap)
%function that takes as input the matrix that has as rows the time seriees
%of each percetile of a fixed risk factor: returnCompound_puntual is a
%5xNdate matrix

cum_pl_LO(1)=0;
for j=1:size(returnCompound_puntual,1)
    bestReturnComp=returnCompound_puntual(j,:); %fix a percentile
    for i=2:length(bestReturnComp)
        puntRet_LO=bestReturnComp(i);
        punt_pl_LO(i)=LOcap(i-1)*(1+puntRet_LO)-LOcap(i-1);
        LOcap(i)=LOcap(i-1)+punt_pl_LO(i);
        cum_pl_LO(i)=cum_pl_LO(i-1)+punt_pl_LO(i);
        returnCompound_perc(i)=cum_pl_LO(i)/abs(LOcap(1)); %vector of cum ret fixed a pecentile
    end
    returnCompound_cum(j,:)=returnCompound_perc;
end
end