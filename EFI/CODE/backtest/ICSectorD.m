function [IC]= ICSectorD(rankMatrix,dateInvolved,rolling,legendaIcb)

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
endDate=dateInvolved(end);
startDate=dateInvolved(end-rolling+1);

endvector= find(rankMatrix(:,1)==endDate);
endPosition=endvector(end);

startvector= find(rankMatrix(:,1)==startDate);
startPosition=startvector(1);

rankRolling=rankMatrix(startPosition:endPosition,2:end); %all but not the first that are dates
for s=1:length(legendaIcb)
     factor_sector{s}=find(rankRolling(:,end)==legendaIcb(s)); %each element of factor_sector contains company position  of each sector
    rankRollingSector=rankRolling(factor_sector{s},1:end-1);
     
    [corrRankMatrix,corrRankReturn]= factorcorr(rankRollingSector);
    IC(s,:)=corrRankMatrix(1,:);
    
    clear ranking_i;
    clear rankMatrix;
end


end

