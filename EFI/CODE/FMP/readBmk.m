function [bmk]=readBmk(filename,dateName)
bmkStruc=datastore(filename,'NumHeaderLines',1,'Range','A:E');

bmkTable=readall(bmkStruc);
startdate=dateName(2);
enddate=dateName(end);
startposition=find(bmkTable.date==startdate);
endposition=find(bmkTable.date==enddate); %con il nuovo datasandwich ho tolto +1

% ***** just to run us data ***** %
% bmk.totRet  = [0;bmkTable{end,3}];
% ***** just to run us data ***** %

bmk.totRet=[0;bmkTable{startposition:endposition,3}];
bmk.cumnetRet=bmkTable {startposition:endposition,4};
bmk.netRet=bmkTable{startposition:endposition,5};
shortbmk=-bmk.totRet';
bmk.cumtotRet(1,1)=0;
bmk.capitalS(1,1)=100;
bmk.capital(1,1)=100;
for i=2:length(shortbmk)
    bmk.capitalS(1,i)=bmk.capitalS(1,i-1)*(1+shortbmk(1,i));
    bmk.capital(1,i)=bmk.capital(1,i-1)*(1-shortbmk(1,i));
    bmk.cumtotRet(1,i)=(bmk.capital(i)-bmk.capital(1))/bmk.capital(1);
end
end