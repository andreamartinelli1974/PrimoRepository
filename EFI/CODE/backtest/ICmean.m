function medianMatrix=ICmean(ICmap,lagMedian,ICB)
    reduxMatrix=ICmap(size(ICmap,1)-lagMedian*length(ICB)+1:size(ICmap,1),:);
    for i=1:length(ICB)
        for j=1:lagMedian
            sectorMatrix(j,:)=reduxMatrix(i+(j-1)*length(ICB),:);
        end
        medianMatrix(i,:)=mean(sectorMatrix);
    end
end