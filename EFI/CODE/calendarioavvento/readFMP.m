function [fmp]=readFMP(filename,reducedRF,risk32)
fmpData=datastore(filename,'Sheet','5Perc_Nocap_SNW_ALLHISTORY');
fmpT=readall(fmpData);
fmp.rfcol=table(fmpT.RF);

if reducedRF==1
   indexes=find(ismember(table2cell(fmp.rfcol),table2cell(risk32)));
   fmptable=fmpT(indexes,:);
else
   fmptable=fmpT;
end

% writetable(fmptable,'tabella_all.xlsx');

i=1;
col=4;
count=1;
while i<=size(fmptable,1)-7 %8 is the number of metrics for each rf
    fmp.rf{count}=fmptable{i,2};
    fmp.longOnly(count,:)=fmptable{i,col:end};
    fmp.ls(count,:)=fmptable{i+5,col:end};
    fmp.rf{count}=fmptable{i,2};
    i=i+8;
    count=count+1;
end
end