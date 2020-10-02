function HistoricalIC=historicalIC(ICmapNorm,learningTime,meanlag,legendaIcb,ref_data_learning)
for i=1:length(legendaIcb)   
    for j=1:length(ref_data_learning)-learningTime+meanlag
        matrix(j,:)=ICmapNorm(i+(j-1)*length(legendaIcb),:);
    end
    HistoricalIC{i}=matrix;
end
end