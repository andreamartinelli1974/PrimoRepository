function [results] = ptfLongShort(indexBest,indexWorst,returnSimple_puntual, returnCompound_puntual, capitalCompound,returnCompound_cum,bmk)
% INPUT
% puntShort  : puntual returns vector of the short position
% puntLong   : puntual returns vector of the long position
%
% OUTPUT
% results: struct

results.capitalLong = capitalCompound(indexBest,:);
results.cumLong = returnCompound_cum(indexBest,:);
results.puntLong = returnCompound_puntual(indexBest,:); %sono i puntauli compound

results.puntShort = -(returnSimple_puntual(indexWorst,:));
results.capitalShort(1)=100;
capitalBMKpunt(1)=100;
capitalBMKpuntNet(1)=100;
results.capitalLongCHK(1)=100;
results.capital_ls(1)=200; %CAPITALE ls BASE 200
results.capital_LS(1)=100;%CAPITALE LS BASE 100

results.capital_LongBMKtot(1)=200;
results.capital_LongBMKnet(1)=200;
results.capital_LBmktot(1)=100;
results.capital_LBmknet(1)=100;

results.capital_LSLeg_eq(1)=200;
results.capital_LongBMKLeg_eq(1)=200;
results.capitalShortLeg(1)=results.capital_LongBMKLeg_eq(1)/2;
results.capitalLongLeg(1)=results.capital_LongBMKLeg_eq(1)/2;
results.capitalBMKLeg(1)=100;


for i=2:length(results.puntShort)
    results.capitalShort(i)= results.capitalShort(i-1)*(1+results.puntShort(i));
    capitalBMKpunt(i)=capitalBMKpunt(i-1)*(1-bmk.totRet(i));
    capitalBMKpuntNet(i)=capitalBMKpuntNet(i-1)*(1-bmk.netRet(i));
    
    %cumu return Short
    results.capitalLongCHK(i)=results.capitalLongCHK(i-1)*(1+results.puntLong(i));
    results.cumShort(i)=(results.capitalShort(i)-results.capitalShort(1))/results.capitalShort(1);
    results.cumBmktot(i)=(capitalBMKpunt(i)-capitalBMKpunt(1))/capitalBMKpunt(1);
    results.cumBmknet(i)=(capitalBMKpuntNet(i)-capitalBMKpuntNet(1))/capitalBMKpuntNet(1);
    
    %capital short base 200
    results.capital_ls(i)=results.capitalShort(i)+results.capitalLongCHK(i);
    results.capital_LongBMKtot(i)=results.capitalLongCHK(i)+capitalBMKpunt(i);
    results.capital_LongBMKnet(i)=results.capitalLongCHK(i)+capitalBMKpuntNet(i);
    
    %capital short base 100
    results.capital_LS(i)=(results.capital_ls(i)/results.capital_ls(i-1))*results.capital_LS(i-1);
    results.capital_LBmktot(i)=(results.capital_LongBMKtot(i)/results.capital_LongBMKtot(i-1))*results.capital_LBmktot(i-1);
    results.capital_LBmknet(i)=(results.capital_LongBMKnet(i)/results.capital_LongBMKnet(i-1))*results.capital_LBmknet(i-1);
    
    %LongShort returns
    results.puntRet_LS(i)=(results.capital_LS(i)-results.capital_LS(i-1))/results.capital_LS(i-1);
    results.cumRet_LS(i)=(results.capital_LS(i)-results.capital_LS(1))/results.capital_LS(1);
    results.puntRet_LBmktot(i)=(results.capital_LBmktot(i)-results.capital_LBmktot(i-1))/results.capital_LBmktot(i-1);
    results.cumRet_LBmktot(i)= (results.capital_LBmktot(i)-results.capital_LBmktot(1))/results.capital_LBmktot(1);
    results.puntRet_LBmknet(i)=(results.capital_LBmknet(i)-results.capital_LBmknet(i-1))/results.capital_LBmknet(i-1);
    results.cumRet_LBmknet(i)=(results.capital_LBmknet(i)-results.capital_LBmknet(1))/results.capital_LBmknet(1);
    
    %LongShort returns_eq
    results.capitalLongLeg(i)= results.capital_LSLeg_eq(i-1)/2*(1+results.puntLong(i));
    
    results.capitalShortLeg(i)= results.capital_LSLeg_eq(i-1)/2*(1+results.puntShort(i));
    results.capital_LSLeg_eq(i)=results.capitalShortLeg(i)+results.capitalLongLeg(i);
    results.puntreturnLS_eq(i)=(results.capital_LSLeg_eq(i)-results.capital_LSLeg_eq(i-1))/results.capital_LSLeg_eq(i-1);
    results.cumreturnLS_eq(i)=(results.capital_LSLeg_eq(i)-results.capital_LSLeg_eq(1))/results.capital_LSLeg_eq(1);
    
    %LongBMK returns_eq
    results.capitalBMKLeg(i)= results.capital_LongBMKLeg_eq(i-1)/2*(1-bmk.totRet(i));
    results.capital_LongBMKLeg_eq(i)=results.capitalLongLeg(i)+results.capitalBMKLeg(i);
    results.puntreturnLBMK_eq(i)=(results.capital_LongBMKLeg_eq(i)-results.capital_LongBMKLeg_eq(i-1))/results.capital_LongBMKLeg_eq(i-1);
    results.cumreturnLBMK_eq(i)=(results.capital_LongBMKLeg_eq(i)-results.capital_LongBMKLeg_eq(1))/results.capital_LongBMKLeg_eq(1);
end



end