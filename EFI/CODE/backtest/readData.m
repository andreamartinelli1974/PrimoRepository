function [sandwichData,cardCompaniesbyDate,ref_data_legend,sedolchkTot]=readData(fileName,savepath)
%% INPUT
% fileName : name of the excel file that has to be
% OUTPUT
%sandwichData: matrix that contains at:
%1° column ref_date
%2° and 3° colum simple and compund return
%from 4° to 68° all the risk factors
%69° ICB code first level

%cardCompaniesbyDate: vector that contains the number of companies at
%each time slice (cleaned from nan values)

%ref_data_legend: vector of all the ref_date in sandwichData

%%

if isfile([savepath,'factortable.mat'])==1
    load([savepath,'factortable.mat']);
else
    importexcel=datastore(fileName,'Range','A:BL');
    factortable=readall(importexcel);
    save([savepath,'factortable.mat'],'factortable');
end
ref_data_table=factortable{2:end-1,1};
sandwichDataRet=factortable{2:end-1,3:4};%the 3 and the 4 colums of factortable are returns
sandwichDataFact=factortable{2:end-1,5:end-2}; %last 2 are ICB codes
sandwichDataICB=factortable{2:end-1,end-1}; %icb 1 level
sandwichData=[ref_data_table sandwichDataRet sandwichDataFact sandwichDataICB]; %create factorMatrix

sedolchkTot=factortable{2:end-1,2};
sedolchk=unique(sedolchkTot);

%remove companies that have Nan value on returns and on sedolchk
index_Na=find(strcmp(sedolchkTot,'@NA'));
sandwichData(index_Na,:)=[];
sedolchkTot(index_Na,:)=[];
index_retNa=find(isnan(sandwichData(:,2)));
sandwichData(index_retNa,:)=[];
sedolchkTot(index_retNa,:)=[];

ref_data=sandwichData(:,1);
ref_data_legend=unique(ref_data);
cardCompaniesbyDate=histc(ref_data,ref_data_legend);

end