function [bmk]=readBmk(filename,datestart,isjustFixed)
% INPUT: filename: file from which bmk has to be read
%learning time: array position of the first considered date

%OUTPUT: structure bmk that contains puntual retuns, capital and cum
%returns
bmkStruc=datastore(filename,'NumHeaderLines',1,'Range','A:E');
bmkTable=readall(bmkStruc);
if isjustFixed==true
    position=find(bmkTable{:,1}==datestart); 
else
    position=find(bmkTable{:,1}==datestart)+1; 
end
bmk.totRet=bmkTable{position:end,3};
bmk.netRet=bmkTable{position:end,5};
bmk.capital(1,1)=100;
bmk.capitalS(1,1)=100;

shortbmk=-bmk.totRet';
for i=2:length(shortbmk)
    bmk.capitalS(1,i)=bmk.capitalS(1,i-1)*(1+shortbmk(1,i));
    bmk.capital(1,i)=bmk.capital(1,i-1)*(1-shortbmk(1,i));
    bmk.cumRet(1,i)=(bmk.capital(i)-bmk.capital(1))/bmk.capital(1);
end
end