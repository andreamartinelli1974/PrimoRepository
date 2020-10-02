clc
clear
close all

%% backTestMAIN

[sandwichData,cardCompaniesbyDate,ref_data_legend,sedolchkTot]=readData('export_.xlsx');
[mapSort]=createMapSort('sortCriteria.xlsx'); %map for sort criteria of each factor (ASC or DESC)
%leggo anche l'ultimo mese che però non ha i ritorni slittati di un mese
%perchè non sono disponibili
[sandwichDataLast]=readData('20191129.xlsx');
%% 
sandwichData=[sandwichData;sandwichDataLast]
ref_data_legend=sandwichData(:,1);
legendaICB=unique(sandwichData(:,end));
risk=datastore('export_.xlsx','Range','E1:BE1');
riskFactors=risk.VariableNames;

%create labels for matrices
rf{1}='SimpleRet';
rf{2}='CompRet';
for i=1:length(riskFactors)
    rf{i+2}=riskFactors{i};
end
%create a vector that contains all the possible combinations between
%factors
count= 1;
for i=1:length(rf)
    for j=i:length(rf)
        riskLegenda{count}=strcat(rf{i},'\',rf{j});
        count=count+1;
    end
end


%% calcolo la rank matrix sul periodo di learning per individuare la stategia
datastart=20091030;
learningTime=find(ref_data_legend==datastart); %tempo iniziale da cui fare learning e coincide con la finestra di rolling
Nperc=10;
rolling=36;
ICtechnique='median'; %string that indicates IC calculation: rolling, increasing, costant or median
meanlag=3;
%%
rf{1}='SimpleRet';
rf{2}='CompRet';
for i=1:length(riskFactors)
    rf{i+2}=riskFactors{i};
end
columnrf=[1:length(rf)];
mapColumn=containers.Map(rf,columnrf);

bmk=readBmk('bmk.xlsx',learningTime);
capitalBmk(1)=100;
shortbmk=-bmk.totRet;
for i=2:length(shortbmk)
capitalBmk(i)=capitalBmk(i-1)*(1+shortbmk(i));
cumRetbmk=(capitalBmk(i)-capitalBmk(1))/capitalBmk(1);
end

%% Back test

% lag=36;
capitalLong(1)=100;
capitalShort(1)=100;
capitalLS(1)=200;
capitalls(1)=100;
capitalLB(1)=200;
capitallb(1)=100;
rfSelected={
'AGRE'...
'DEBT_MKT_CAP'...
'EPSDISP'...
'EREV'...
'LRE'...
'PCTCHG_EBITDA'...
'PCTCHG_EQUITY'...
'PCTCHG_NET_DEBT'...
'PM6M'...
'RC1MEREV'...
'ROE'...
'UL_SALES'

};

 for i=1:length(ref_data_legend)
        cardCompaniesbyDate(i)=histc(sandwichData(:,1),ref_data_legend(i));
end
[~,~,rankMatrix]=factorRankcorrSector(sandwichData(:,1:end),cardCompaniesbyDate,mapSort,rf,legendaICB);


for i=1:size(rfSelected,2)
        col(i)=mapColumn(rfSelected{1,i});
end

first_refdateVec=ref_data_legend(1:learningTime);
ICWeigths=zeros(10,length(rf)); 
ICWeigthsNorm=zeros(10,length(rf));
for i=1:meanlag-1
    ICWeigths_lastdate=ICSectorD([sandwichData(:,1) rankMatrix sandwichData(:,end)],first_refdateVec(end-(meanlag-i),1),1,legendaICB);
    ICWeigths(:,col)=ICWeigths_lastdate(:,col);
    ICWeigthsNorm_lastdate=normalizeWeigths(ICWeigths);
    if i==1
       ICmap=ICWeigths;
       ICmapNorm=ICWeigthsNorm_lastdate;
    else 
       ICmap=[ICmap;ICWeigths]; 
       ICmapNorm=[ICmapNorm;ICWeigthsNorm_lastdate];
    end
end

for t=1:size(ref_data_legend,1)-learningTime
    ref_data_learning=ref_data_legend(1:t+learningTime-1); %array of dates involved in learning period
    %number of companies in each time slices used to learn
    for i=1:length(ref_data_learning)
        cardCompaniesbyDateLearning(i)=histc(sandwichData(:,1),ref_data_learning(i));
    end
    endPosition=sum(cardCompaniesbyDateLearning); %position in data sandwich of the last element used to learn
    
    
    if t==1
        dataSandwichLearning=sandwichData(1:endPosition,:); %subsection of sandwichData used to learn
        sedolchkLearning = sedolchkTot(1:endPosition,:);
    else
        dataSandwichLearning=[dataSandwichLearning;sandwichData((endPosition-cardCompaniesbyDateLearning(end))+1:endPosition,:)];% append the next time slice to the sandwich
    end 
     
    %following we have 3 differet ways to calculate IC coef, involved in the
    %scose calculation: rolling window, expanding window and costant values
    
     ICWeigths=zeros(10,length(rf)); 
     ICWeigthsNorm=zeros(10,length(rf));
     
   switch ICtechnique
       case 'rolling'
%            [ICWeigths_tot,rankMatrix]=ICSectorDynamic(dataSandwichLearning,mapSort,rf,ref_data_learning,rolling,legendaICB);
            ICWeigths_tot=ICSectorD([sandwichData(:,1) rankMatrix sandwichData(:,end)],ref_data_learning,rolling,legendaICB);
            ICWeigths(:,col)=ICWeigths_tot(:,col);%copy just Ic of selected rf, zero otherwise
            ICWeigthsNorm=normalizeWeigths(ICWeigths);
       case 'increasing'
%            ICWeigths_tot=ICSectorDynamic(dataSandwichLearning,mapSort,rf,ref_data_learning,length(ref_data_learning),legendaICB);
            ICWeigths_tot=ICSectorD([sandwichData(:,1) rankMatrix sandwichData(:,end)],ref_data_learning,length(ref_data_learning),legendaICB);
            ICWeigths(:,col)=ICWeigths_tot(:,col);%copy just Ic of selected rf, zero otherwise
            ICWeigthsNorm=normalizeWeigths(ICWeigths);
       case 'costant'
            %matrix that have as row no zero weigths for the selected factors and zero for all the others 
            ICWeigthsNorm(:,col)=10^(-12)*floor((1/size(rfSelected,2)*10^12));  
       case 'median'
            ICWeigths_lastdate=ICSectorD([sandwichData(:,1) rankMatrix sandwichData(:,end)],ref_data_learning,1,legendaICB); 
            ICWeigths(:,col)=ICWeigths_lastdate(:,col);
            ICmap=[ICmap;ICWeigths];
            
            ICWeigthsNorm_lastdate=normalizeWeigths(ICWeigths);
            ICmapNorm=[ICmapNorm;ICWeigthsNorm_lastdate];
            ICWeigths_tot=ICmean(ICmap,meanlag,legendaICB);
            ICWeigthsNorm=normalizeWeigths(ICWeigths_tot);
            
            
   end

    
    %score are calculated out of sample
    ref_data_ptf=ref_data_legend(length(ref_data_learning)+1);% date that referes to rf
    ptfPositions=find(sandwichData(:,1)==ref_data_ptf);
    
    timeslice=sandwichData(ptfPositions(1):ptfPositions(end),:);
    sedolchtTimeSlice=sedolchkTot(ptfPositions(1):ptfPositions(end),:);
    retVectors = timeslice(:,2:3);
    cardTimeSlice = size(timeslice,1);  
    [matrixSliceRank]= calculateRankMatrixS (timeslice,cardTimeSlice,rf,mapSort,legendaICB);
    for code=1:length(legendaICB)
        icb=legendaICB(code);
        index_sector=find(timeslice(:,end)==icb);
        sedolchkSector=sedolchtTimeSlice(index_sector);
        matrixSector=timeslice(index_sector,:); 
        matrixSectorRank=matrixSliceRank(index_sector,:);%all columns but the last (ICB code)
        %functions that returns scores for each company and a matrix that has
        %as colums the ranked winner rf 
        [scores]= scoreVector(ICWeigthsNorm(code,:),matrixSectorRank);
        retMatrix= matrixSector(:,2:3); %extract the datasandwich' columns that refer to returns
        
        %for each ICB sector Nperc ptfs are created, chosing comapanies by score 
        [ptfSector]= createPtf1(sedolchkSector,[retMatrix scores],Nperc,cardTimeSlice,legendaICB);
        
        %append each ptfSector in the proper PTF
        if code==1
           for i=1:Nperc
                ptf(i).weigths=ptfSector(i).weigths;
                ptf(i).returnSimple=ptfSector(i).returnSimple;
                ptf(i).returnCompound=ptfSector(i).returnCompound;
                ptf(i).members=ptfSector(i).members;
           end
        else
            for i=1:Nperc
                ptf(i).weigths=[ptf(i).weigths;ptfSector(i).weigths];
                ptf(i).returnSimple=[ptf(i).returnSimple;ptfSector(i).returnSimple];
                ptf(i).returnCompound=[ptf(i).returnCompound;ptfSector(i).returnCompound];
                ptf(i).members=[ptf(i).members;ptfSector(i).members];
            end
        end
       clear ptfSector;
    end    
    
    %PTF simple seturns are linear combinations of returns of each
    %companies
    for i=1:length(ptf)
        %eqweights=ones(size(ptf(i).members,1),1)*1/size(ptf(i).members,1);
        ptf(i).returnSimplePTF=ptf(i).returnSimple'*ptf(i).weigths;
        ptf(i).returnCompundPTF=ptf(i).returnCompound'*ptf(i).weigths;
        
    end
    
    %returns of the first ptf
    bestReturnSimple(t+1)=ptf(1).returnSimplePTF;
    bestReturnComp(t+1)=ptf(1).returnCompundPTF;
    
    %cumulative returns calcultation
    shortRetSimple(t+1)=-ptf(end).returnSimplePTF;
    capitalLong(t+1)=capitalLong(t)*(1+ptf(1).returnCompundPTF);
    capitalShort(t+1)=capitalShort(t)*(1+shortRetSimple(t+1));
    capitalLS(t+1)=capitalLong(t+1)+capitalShort(t+1);
    capitalls(t+1)= capitalLS(t+1)/2; %capital long short base 100
    
    %longBMK
    capitalLB(t+1)=capitalLong(t+1)+capitalBmk(t+1);
    capitallb(t+1)= capitalLB(t+1)/2; %capital long short base 100
    
    
    cumRetPTF(t+1)=(capitalLong(t+1)-capitalLong(1))/capitalLong(1);
    cumRetPTFLS(t+1)=(capitalls(t+1)-capitalls(1))/capitalls(1);
    cumRetPTFLB(t+1)=(capitallb(t+1)-capitallb(1))/capitallb(1);
    
    puntretLS(t+1)=(capitalls(t+1)-capitalls(t))/capitalls(t);
    puntretLB(t+1)=(capitallb(t+1)-capitallb(t))/capitallb(t);
    clear ptf;
end
    productRet=prod(1+ bestReturnSimple(2:end));
    annulizedRet=-1+(productRet^(12/length(puntretLB)));
    annualizedVol=sqrt(12)*std(bestReturnSimple(2:end));
    SR_AR_AV=annulizedRet/annualizedVol;      
    matrix=[bestReturnComp;cumRetPTF;cumRetPTFLS;cumRetPTFLB;puntretLS;puntretLB];
    historicalIC=historicalIC(ICmap,learningTime,meanlag,legendaICB,ref_data_learning);
    filename = 'IC_completo.xlsx';
    for i=1:length(legendaICB)
        label=strcat('ICB','_',num2str(legendaICB(i,1)));
        histIC=historicalIC{i};
        ic{i}=histIC(:,col);
%         writematrix(ic{i},filename,'Sheet',label ,'Range','D2')
    end
   
   
    
    
            
            
