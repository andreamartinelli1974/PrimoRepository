function [corrRankMatrix,corrRankReturn]= factorRankcorr (sandwichData,cardCompaniesbyDate,mapSort,rf)

%INPUT: sandwichData that contains ref_data, returns and factors. Ref_data
%because companies are ranked time independentlly

%OUTPUT: CorrRankMatrix : correlation Matrix between rank factors

startpoint=1;
for t=1:size(cardCompaniesbyDate,1)
 
    endpoint=startpoint+cardCompaniesbyDate(t)-1; %position in dataSandwich of the last company of the timeslice
    
    %sandwichdata Slice that refers to a fixed ref_date
    timeslice= sandwichData(startpoint:endpoint,2:end); %prendo la fetta di una data togliendo la colonna delle ref_date
    
    for factor=1:size(timeslice,2) 
        factor_i=timeslice(:,factor);
        
        sortCriteria=mapSort(rf{factor}); %ASC OR DESC
        [sortfactor_i]=sort(factor_i,sortCriteria); %sort factor by its own criteria
        
        %find rank positions
        sortunque=unique(sortfactor_i,'stable');
            for k=1:length(factor_i)
                if isnan(factor_i(k))==1 %to a NaN value corresponds a Nan rank
                    ranking_i(k)=nan;
                    continue;
                end
                
                pos=find(sortunque==factor_i(k));
                ranking_i(k)=pos; %vector of rank
                
%                 if histc(cardCompaniesbyDate(t),ranking_i)> 0.2*length(ranking_i)
%                    break;
%                 end
            end
        rankMatrix(startpoint:endpoint,factor)=ranking_i;  %insert vector in the rank matrix
        
    end
    clear ranking_i
    startpoint=endpoint+1; %change timeslice
end

    [corrRankMatrix,corrRankReturn]= factorcorr(rankMatrix); %correlations between rank
end

