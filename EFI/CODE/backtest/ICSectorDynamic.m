function [IC,rankMatrix]= ICSectorDynamic(timeslice,mapSort,rf,dateInvolved,back,legendaIcb)

%% INPUT 
% sandwichData: matrix that contains ref_date, all the rf and ICB code
% cardCompaniesbyDate: vector that contains the number of companies at each
%                      timeslice
% mapSort: map that given a rf returns sort criteria (ASC, DESC)
% rf: list of risk factor considered

% OUTPUT:
%  corrRankmatrix: correlation matrix between risk factors rank, ranking companies
%  time and sector independentlly.



%find in each timeslice positions for each sector
for s=1:length(legendaIcb)
     factor_sector{s}=find(timeslice(:,end)==legendaIcb(s)); %each element of factor_sector contains company position  of each sector

     timesliceSector= timeslice(factor_sector{s},2:end);
     dateTime=timeslice(factor_sector{s},1);
    for factor=1:size(timesliceSector,2)-1 %all rf but the ICB code
        factor_i=timesliceSector(:,factor); %fix factor
        sortCriteria=mapSort(rf{factor});
        for slice=1:back
            if slice==1
                startRank=1;
            else
                startRank=endRank+1;
            end
            endVector=find(dateTime==dateInvolved(slice));
            if length(endVector)==0
                x='errore';
            end
            endRank=endVector(end);
            factor_iSlice=factor_i(startRank:endRank);
            [sortfactor_i]=sort(factor_iSlice,sortCriteria);
            sortunque=unique(sortfactor_i,'stable');
            for k=1:length(factor_iSlice)
                if isnan(factor_iSlice(k))==1
                    pos(k)=nan;%vector of rank for the s-th sector
                    continue;
                end
                
                pos(k)=find(sortunque==factor_iSlice(k));
            end
            
            ranking_i(startRank:endRank)=pos; %vector that cointains rank position of all sectors
            clear pos;
        end
            rankMatrix(:,factor)=ranking_i; %matrix of rank positions for each factor and each timeslice
            
    end
    [corrRankMatrix,corrRankReturn]= factorcorr(rankMatrix);
    IC(s,:)=corrRankMatrix(1,:);
    
    clear ranking_i;
    clear rankMatrix;
end


end

