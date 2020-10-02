function [corrRankMatrix,corrRankReturn,rankMatrix]= factorRankcorrSector (sandwichData,cardCompaniesbyDate,mapSort,rf,legendaIcb)

%% INPUT 
% sandwichData: matrix that contains ref_date, all the rf and ICB code
% cardCompaniesbyDate: vector that contains the number of companies at each
%                      timeslice
% mapSort: map that given a rf returns sort criteria (ASC, DESC)
% rf: list of risk factor considered

% OUTPUT:
%  corrRankmatrix: correlation matrix between risk factors rank, ranking companies
%  time and sector independentlly.


startpoint=1;
for t=1:size(cardCompaniesbyDate,1)
    
    endpoint=startpoint+cardCompaniesbyDate(t)-1;%position in datasanwich of the last element of the timeslice
    
    timeslice= sandwichData(startpoint:endpoint,2:end); %prendo la fetta di una data togliendo la colonna delle ref_date
    
    %find in each timeslice positions for each sector
    for s=1:length(legendaIcb)
        factor_sector{s}=find(timeslice(:,end)==legendaIcb(s)); %each element of factor_sector contains company position  of each sector
    end
    
    for factor=1:size(timeslice,2)-1 %all rf but the ICB code
        factor_i=timeslice(:,factor); %fix factor
        sortCriteria=mapSort(rf{factor});
     
        for s=1:length(legendaIcb) %rank is time and sector indipendent: for each timeslice and for each sector rank starts from one
            indexes_sector=factor_sector{s};
            factor_isec=factor_i(indexes_sector); %array that contains 
            [sortfactor_i]=sort(factor_isec,sortCriteria,'MissingPlacement','last');
            sortunque=unique(sortfactor_i,'stable');
            for k=1:length(factor_isec)
                if isnan(factor_isec(k))==1
                    ranking_i(indexes_sector(k))=nan;%vector of rank for the s-th sector
                    continue;
                end
                
                pos=find(sortunque==factor_isec(k));
                ranking_i(indexes_sector(k))=pos; %vector that cointains rank position of all sectors
                
  
            end
        end
        rankMatrix(startpoint:endpoint,factor)=ranking_i; %matrix of rank positions for each factor and each timeslice
        
    end
    clear ranking_i
    startpoint=endpoint+1; %change timeslice
end

[corrRankMatrix,corrRankReturn]= factorcorr(rankMatrix);
end

