function [vector] = manage_nan(vector, sortFactor)
% INPUTS:
% vector: vector that contains factor's values, fixed time
% sortFactor: "ASC" or "DESC"
% OUTPUTS:
% 
% sortedVector: vector whithout NaN values and sorted ascending or
% descending

% FUNCTION
% manage NaN values by the asc or desc rules.

% search position of Nan Data
nan_pos = isnan(vector);
[nan_index] = find(nan_pos==1);

% clean matrix
cleanVector = vector;
cleanVector(nan_index, :) = [];
avarege= mean(cleanVector);
standDevi=std(cleanVector);
if (sortFactor=="ASC")
    vector(nan_index) = avarege+3*standDevi;
else
    vector(nan_index) = avarege-3*standDevi;
end
end

