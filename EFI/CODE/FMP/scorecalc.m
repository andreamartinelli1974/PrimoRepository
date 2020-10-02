function [scorevector]=scorecalc(matrix)
scorevector=zeros(size(matrix,2),1);
for i=1:size(matrix,2)
    for j=i+1:size(matrix,2)
        if (size(find(matrix(:,i)>matrix(:,j)),1))>0.5*size(matrix,1)
            scorevector(i)=scorevector(i)+1;
        else
            scorevector(j)=scorevector(j)+1;
        end
    end
end

end