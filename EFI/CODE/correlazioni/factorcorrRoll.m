function [corrRankMatrixRoll,corrRankReturnRoll,startDate,endDate]=factorcorrRoll(dataSandwich,ref_data_legend,rollig)
%% INPUT 
% dataSandwich: Matrix that contains returns and factors
% ref_data_legenda: vector of ref_data

%% OUTPUT
% corrRankMatrixRoll: cell array that contains 148correlation matrixes( one for each
% rolling window (171-23=148))

for i=1:length(ref_data_legend)-(rollig-1)
    startDate(i)=ref_data_legend(i);
    endDate(i)=ref_data_legend(i+(rollig-1));
    start=find(dataSandwich(:,1)==ref_data_legend(i));
    startpoint=start(1);
    endp=find(dataSandwich(:,1)==ref_data_legend(i+(rollig-1)));
    endpoint=endp(end);
    [corrRankMatrix,corrRankReturn]= factorcorr(dataSandwich(startpoint:endpoint,2:end));%perchè la prima è la ref_date
    corrRankMatrixRoll{i}=corrRankMatrix;
    corrRankReturnRoll{i}=corrRankReturn;
    
end

end