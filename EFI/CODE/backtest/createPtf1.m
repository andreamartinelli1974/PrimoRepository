function [ptf]=createPtf1 (sedolchkSector,sectorMatrix,Nperc, card_timeslice,legendaICB)

%% INPUT: 
%sedolchkSector: companies of each sectors in the timeslice;
%sectorMatrix: matrix that have as first and second columns the returns of
%each sedolchkSector 
%Nperc: number of ptf to construct for each sector
%card_timeslice: number of companies in the timeslice (used for the weigths calculation)

%OUTPUT: ptf: Nperc struct that have the following properties:
% weights, members, returnSimple (ret of each members in the i-sm ptf),
% retCompund



card_sector = size(sectorMatrix,1);
[sortedScore, index_score]= sort(sectorMatrix(:,end)); %the best companies have minor score
%companies SORTED ASCENDING
retunSimple= sectorMatrix(:,1);
retunSimpleSorted=retunSimple(index_score);
retunCompound = sectorMatrix(:,2);
retunCompoundSorted=retunCompound(index_score);
sedolchkSorted=sedolchkSector(index_score);
[startVector,endVector,count]=dividePercentile(sortedScore,Nperc);
for i=1:Nperc
    ptf(i).weigths =ones(count(i),1)* (1/count(i)*(card_sector/card_timeslice));%weigths of companies in the ptf
    ptf(i).members=sedolchkSorted(startVector(i):endVector(i),1);
    ptf(i).returnSimple=retunSimpleSorted(startVector(i):endVector(i),1);
    ptf(i).returnCompound=retunCompoundSorted(startVector(i):endVector(i),1);
end

end