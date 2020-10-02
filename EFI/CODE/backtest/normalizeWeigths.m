function [normWeigths]= normalizeWeigths (weigths)
for r=1:size(weigths,1)
  vetorWeigths= weigths(r,:);
  minimum= min(vetorWeigths);
  if minimum<0
     index=find(vetorWeigths~=0);
     vetorWeigths(1,index)=abs(minimum)+vetorWeigths(1,index);
  end
  sumVector=sum(vetorWeigths);
  normW=vetorWeigths./sumVector;
  normWeigths(r,:)=normW;
end
  
end