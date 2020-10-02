function [corrHistorical]=historicalmatrix (matriceArray)

% INPUT: matriceArray: cell array that contains 148 correlation matrixes( one for each
% rolling window (171-23=148))

%OUTPUT: corrHistorical: matrix that has at each row the historical
%behavior of the correlation coefficients between factors in rolling windows. Each row has 148
%elements as the number of rolling windows
for t=1:size(matriceArray,2)
        matrice=matriceArray{1,t};
        startpoint=1;
        for i=1:size(matrice,1)
            vettore=matrice(i,i:end);
            endpoint=startpoint+length(vettore)-1;
            corrHistorical(startpoint:endpoint,t)=vettore;
            startpoint=endpoint+1;
           
        end
end
end