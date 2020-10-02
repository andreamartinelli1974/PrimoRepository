function [corrMatrix]= factorcorr_factor(sandwichDataFact)
corrMatrix=zeros(size(sandwichDataFact,2));
for i=1:size(sandwichDataFact,2) %all rf but the returns
 nan_pos = isnan(sandwichDataFact(:,i)); 
 [nan_row, ~] = find(nan_pos==1);

 % clean matrix 
 cleanMatrix = sandwichDataFact;
 cleanMatrix(nan_row, :) = [];  
 corrcoefMatrix=corrcoef(cleanMatrix(:,i),cleanMatrix(:,i));
 corrMatrix(i,i)= corrcoefMatrix(1,1);
 for j=i+1:size(sandwichDataFact,2)
     factor_i=cleanMatrix(:,i);
     factor_j=cleanMatrix(:,j);
     factors_ij=remove_nan([factor_i,factor_j]);
     corrcoefMatrix=corrcoef(factors_ij(:,1),factors_ij(:,2));
     corrMatrix(j,i)=corrcoefMatrix(1,2);
     corrMatrix(i,j)=corrMatrix(j,i);
 end    
end

end