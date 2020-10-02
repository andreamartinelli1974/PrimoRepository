function [sortMap]=createMapSort(filename)
riskfactor= datastore(filename,'Sheet','Sheet1','Range','B:B');
rftable=readall(riskfactor);
rf=rftable{:,:};

riskfactortRank= datastore(filename,'Sheet','Sheet1','Range','D:D');
riskfactortRankTable=readall(riskfactortRank);
RFrank=riskfactortRankTable{:,:};

sortMap=containers.Map(rf,RFrank);

end
