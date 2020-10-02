function [cleanMatrix,nan_row] = remove_nan(matrix)
% INPUTS:
%  matrix: matrix of values
% 
% OUTPUTS:
% cleanMatrix: is the original matrix without the raws that contains at least one Nan value
% 
% FUNCTION
% remove the Nan function from the matrix

% search position of Nan Data
 nan_pos = isnan(matrix); 
 [nan_row, ~] = find(nan_pos==1);

 % clean matrix 
 cleanMatrix = matrix;
 cleanMatrix(nan_row, :) = [];
 
end 

