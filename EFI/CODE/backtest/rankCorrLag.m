function [corrRankMatrix,corrRankReturn,corrRetMat]= rankCorrLag (sliceTime,mapSort,rf)
%% devo passare la timeslice senza date
load('legendaICB');

%find in each timeslice positions for each sector. Is a cell array that
%contains indexes of position each sector
timeslice=sliceTime(:,2:end); %data column has to be taken off
for s=1:length(legendaIcb)
    factor_sector{s}=find(timeslice(:,end)==legendaIcb(s)); %each element of factor_sector contains company position  of each sector
end

for s=1:length(legendaIcb) %rank is time and sector indipendent: for each timeslice and for each sector rank starts from one
        indexes_sector=factor_sector{s};
        subTimeSliceSector=timeslice(indexes_sector,1:end-1);%subtimeslice by sector without last column
        for factor=1:size(timeslice,2)-1 %all rf but the ICB code
            factor_i=subTimeSliceSector(:,factor); %fix factor
            sortCriteria=mapSort(rf{factor});
            [sortfactor_i]=sort(factor_i,sortCriteria);
            sortunque=unique(sortfactor_i,'stable');
            for k=1:length(factor_i)
                if isnan(factor_i(k))==1
                    ranking_i(k)=nan;%vector of rank for the s-th sector
                continue;
                end
            pos(k)=find(sortunque==factor_i(k)); %vector that cointains rank position of all sectors   
            end
            
            rankMatrixSector(:,factor)=pos; %matrix of rank positions for each factor and each timeslice
    end
    [corrRankMatrix,corrRankReturn]= factorcorr(rankMatrixSector);
    corrRetMat(s,:)=corrRankMatrix(:,1);
    clear pos;
    clear rankMatrixSector;
    clear factr_i;
end
end