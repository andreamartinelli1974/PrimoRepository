function [corrMatrix,corrReturn,corrcoefSperman]= factorcorr(sandwichDataFact)

%% INPUT 
   %sandwichData : that contains only returns and factors (No ref_date, no ICB code )
%% OUTPUT 
   %corrMatrix : correlation Matrix (Square matrix 67x67) between factors and returns
%% function:
corrMatrix=nan(size(sandwichDataFact,2));

for i=1:size(sandwichDataFact,2) 
 nan_pos = isnan(sandwichDataFact(:,i)); 
 [nan_row, ~] = find(nan_pos==1);

 % matrix has to be clened by NaN value of factors
 cleanMatrix = sandwichDataFact;
 cleanMatrix(nan_row, :) = [];  
 
 %cutoff value is 20% of the entire sample
 valoresoglia=0.2*size(sandwichDataFact(:,i),1);
 if size(cleanMatrix(:,i),1)< valoresoglia %if the number of NaN is more than 20%, the next factor is taken
     continue;
 end
 
 factor_i=cleanMatrix(:,i);
 
 % by the fact that matlab doesn't manage Nan value, we need to run
 % correlation for each pairs of factors cleaned by Nan
 
 %controll on corrMatrix that by definition has value 1 on diagonal
 corrcoefMatrix=corrcoef(factor_i,factor_i);
 corrMatrix(i,i)= corrcoefMatrix(1,1);
 
 %to take advantage from symmetry of correlation Matrix we consider
 %correlation from factor i and all the next factors. 
 for j=i+1:size(sandwichDataFact,2) 
     factor_j=cleanMatrix(:,j);
     factors_ij=remove_nan([factor_i,factor_j]);
        if size(factors_ij(:,1),1)< 0.2*size(factor_i,1)
           continue;
        end
     corrcoefMatrix=corrcoef(factors_ij(:,1),factors_ij(:,2));
     corrMatrix(j,i)=corrcoefMatrix(1,2);
     corrMatrix(i,j)=corrMatrix(j,i);
     
 end    
     factor_iReturn = remove_nan([cleanMatrix(:,i),cleanMatrix(:,2)]);
     corrcoefMatrixReturn=corrcoef(factor_iReturn(:,1),factor_iReturn(:,2));
     
     corrReturn(i,1)= corrcoefMatrixReturn(1,2);
end

end