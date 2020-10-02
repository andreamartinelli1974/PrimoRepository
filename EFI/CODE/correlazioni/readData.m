function [sandwichData,cardCompaniesbyDate,ref_data_legend,rf]=readData(fileName,rfreduced,reduceRF_flag)
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
% importexcel=datastore(fileName);
% factortable=readall(importexcel);
load('factortable.mat');

rf= factortable.Properties.VariableNames(1:end-2); %all but the ICB code
ref_data_table=factortable{2:end-1,1};
sandwichDataRet=factortable{2:end-1,3:4};%the 3 and the 4 colums of factortable are returns
sandwichDataFact=factortable{2:end-1,5:end-2}; %last 2 are ICB codes
sandwichDataICB=factortable{2:end-1,end-1}; %icb 1 level
sandwichDataM=[ref_data_table sandwichDataRet sandwichDataFact sandwichDataICB]; %create factorMatrix

sedolchkTot=factortable{2:end-1,2};
sedolchk=unique(sedolchkTot);

%remove companies that have Nan value on returns and on sedolchk
index_Na=find(strcmp(sedolchkTot,'@NA'));
sandwichDataM(index_Na,:)=[];
sedolchkTot(index_Na,:)=[];
index_retNa=find(isnan(sandwichDataM(:,2)));
sandwichDataM(index_retNa,:)=[];
sedolchkTot(index_retNa,:)=[];

if reduceRF_flag==1
    for i=1:length(rfreduced)
        index_rf(i)=(find(strcmp(rfreduced{i},rf))-1); %-1 beacause sedolchk colum was removed
    end
   sandwichData=[sandwichDataM(:,1) sandwichDataM(:,index_rf) sandwichDataM(:,end)];
else
   sandwichData=sandwichDataM;
end

ref_data=sandwichData(:,1);
ref_data_legend=unique(ref_data);
cardCompaniesbyDate=histc(ref_data,ref_data_legend);
end