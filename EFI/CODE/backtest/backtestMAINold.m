clc
clear
close all

userId = getenv('USERNAME');
addpath(['C:\Users\',userId,'\Desktop\EFI\CODE\input']);
addpath(['C:\Users\',userId,'\Desktop\EFI\CODE\input\anagrafiche']);
outputpath= 'C:\Users\u369343\Desktop\EFI\CODE\output\backtest\';

%% INPUT
%string that indicates IC calculation: rolling, increasing, costant or median

% ICtechniqueVec={'MovingAverage3M'}; 
% ICtechniqueVec={'FixedWeights'};
% ICtechniqueVec={'Rolling36M'};
ICtechniqueVec={'MovingAverage3M''FixedWeights''Rolling36M'};

Nperc=10;
rolling=36;
meanlag=3;


%% backTestMAIN
tic
[sandwichData,cardCompaniesbyDate,ref_data_legend,sedolchkTot]=readData('datasandwich.xlsx');
[mapSort]=createMapSort('sortCriteria.xlsx'); %map for sort criteria of each factor (ASC or DESC)
%leggo anche l'ultimo mese che però non ha i ritorni slittati di un mese
%perchè non sono disponibili

%%
legendaICB=unique(sandwichData(:,end));
risk=datastore('datasandwich.xlsx','Range','E1:BJ1');
riskFactors=risk.VariableNames;

%create labels for matrices
rf{1}='SIMPLE_TOT_RET';
rf{2}='COMPOUND_TOT_RET';
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

if strcmp(ICtechniqueVec,'Rolling36M') || length(ICtechniqueVec)==3
datastart=20080331; %insert data that return zero in the time series
elseif strcmp(ICtechniqueVec,'MovingAverage3M')
datastart=20050630;
elseif strcmp(ICtechniqueVec,'FixedWeights')
datastart=20050429;

end

learningTime=find(ref_data_legend==datastart); %tempo iniziale da cui fare learning e coincide con la finestra di rolling
%%

columnrf=[1:length(rf)];
mapColumn=containers.Map(rf,columnrf);

%% Back test

%cellarray that contains rf of each strategy
[strategieTable]=readRfStrategies('strategies.xlsx');
involvedStrategies=[strategieTable.STRATEGIA1B strategieTable.STRATEGIA5 strategieTable.STRATEGIA7 strategieTable.STRATEGIA8];

if  length(ICtechniqueVec)==1 && strcmp(ICtechniqueVec,'FixedWeights')
    endPoint=size(ref_data_legend,1);
    startdate=datetime(datestr(datenum(num2str(ref_data_legend(1)),'yyyymmdd')));
    isjustFixedWeigthed=true;
else
    endPoint=size(ref_data_legend,1)-learningTime;
    startdate=datetime(datestr(datenum(num2str(ref_data_legend(learningTime+1)),'yyyymmdd')));
    isjustFixedWeigthed=false;
end

enddate=dateshift(datetime(datestr(datenum(num2str(ref_data_legend(end-1)),'yyyymmdd'))),'end','month','next');
timeseries=datetime(busdays(startdate,enddate,'monthly'));

bmk=readBmk('bmk.xlsx',datastart,isjustFixedWeigthed);

for s=1:size(involvedStrategies,2)
    rfSelected=cleanRF(involvedStrategies(:,s))';
    
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
    
    
    for tec=1:length(ICtechniqueVec)
        ICtechnique=char(ICtechniqueVec(tec));
        
        if strcmp(ICtechnique,'MovingAverage3M')
            for i=1:meanlag-1
                dateUsed=first_refdateVec(end-(meanlag-i),1);
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
        end

        for t=1:endPoint
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
                case 'Rolling36M'
                    %            [ICWeigths_tot,rankMatrix]=ICSectorDynamic(dataSandwichLearning,mapSort,rf,ref_data_learning,rolling,legendaICB);
                    ICWeigths_tot=ICSectorD([sandwichData(:,1) rankMatrix sandwichData(:,end)],ref_data_learning,rolling,legendaICB);
                    ICWeigths(:,col)=ICWeigths_tot(:,col);%copy just Ic of selected rf, zero otherwise
                    ICWeigthsNorm=normalizeWeigths(ICWeigths);
                case 'increasing'
                    %            ICWeigths_tot=ICSectorDynamic(dataSandwichLearning,mapSort,rf,ref_data_learning,length(ref_data_learning),legendaICB);
                    ICWeigths_tot=ICSectorD([sandwichData(:,1) rankMatrix sandwichData(:,end)],ref_data_learning,length(ref_data_learning),legendaICB);
                    ICWeigths(:,col)=ICWeigths_tot(:,col);%copy just Ic of selected rf, zero otherwise
                    ICWeigthsNorm=normalizeWeigths(ICWeigths);
                case 'FixedWeights'
                    %matrix that have as row no zero weigths for the selected factors and zero for all the others
                    ICWeigthsNorm(:,col)=(1/size(rfSelected,2));
                case 'MovingAverage3M'
                    ICWeigths_lastdate=ICSectorD([sandwichData(:,1) rankMatrix sandwichData(:,end)],ref_data_learning,1,legendaICB);
                    ICWeigths(:,col)=ICWeigths_lastdate(:,col);
                    ICmap=[ICmap;ICWeigths];
                    
                    ICWeigthsNorm_lastdate=normalizeWeigths(ICWeigths);
                    ICmapNorm=[ICmapNorm;ICWeigthsNorm_lastdate];
                    ICWeigths_tot=ICmean(ICmap,meanlag,legendaICB);
                    ICWeigthsNorm=normalizeWeigths(ICWeigths_tot);
                    
                    
            end
            
            
            
            if isjustFixedWeigthed==true
                ref_data_ptf=ref_data_legend(length(ref_data_learning));% fixedweigthed doesn't need to learn
            else
                ref_data_ptf=ref_data_legend(length(ref_data_learning)+1);%score are calculated out of sample ADD +1
            end
            
            ptfPositions=find(sandwichData(:,1)==ref_data_ptf);
            timeslice=sandwichData(ptfPositions(1):ptfPositions(end),:);
            sedolchtTimeSlice=sedolchkTot(ptfPositions(1):ptfPositions(end),:);
            
            
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
                
                if t==endPoint 
                    zeroICB=length(find(timeslice(:,end)==0));
                    cardTimeSlice = size(timeslice,1)-zeroICB;
                    [sortedScore, index_score]= sort(scores);
                    sedolchkSorted=sedolchkSector(index_score);
                    [startVector,endVector,count]=dividePercentile(sortedScore,Nperc);
                    
                    card_sector=length(index_sector);
                    for i=1:Nperc
                        ptfTodaySector(i).members=sedolchkSorted(startVector(i):endVector(i),1);
                        ptfTodaySector(i).weigths =ones(count(i),1)* (1/count(i)*(card_sector/cardTimeSlice));
                        if code==1
                            ptfToday(i).members=ptfTodaySector(i).members;
                            ptfToday(i).weigths=ptfTodaySector(i).weigths;
                        else
                            ptfToday(i).members=[ptfToday(i).members;ptfTodaySector(i).members];
                            ptfToday(i).weigths=[ptfToday(i).weigths;ptfTodaySector(i).weigths];
                        end
                    end
                    continue;
                end
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
            if t==endPoint 
                membersLO=ptfToday(1).members;
                membersSO=ptfToday(end).members;
                weigthsLO=ptfToday(1).weigths;
                weigthsSO=ptfToday(end).weigths;
                members=[membersLO;membersSO];
                weigths=[weigthsLO;weigthsSO];
                labelLO_SO=[repmat('CompositionLO',size(membersLO,1),1);repmat('CompositionSO',size(membersSO,1),1)];
                matrixMemberNew=table(repmat(strategieTable.Properties.VariableNames(s),size(members,1),1),repmat({ICtechnique},size(members,1),1),repmat(timeseries(t,:),size(members,1),1),labelLO_SO,members,weigths);
                matrixMember=[matrixMember;matrixMemberNew];
                break;
            end
            %PTF simple seturns are linear combinations of returns of each
            %companies
            for i=1:length(ptf)
                
                ptf(i).returnSimplePTF=ptf(i).returnSimple'*ptf(i).weigths;
                ptf(i).returnCompundPTF=ptf(i).returnCompound'*ptf(i).weigths;
                
            end
            
            bestReturnComp(t+1)=ptf(1).returnCompundPTF;
            shortRetSimple(t+1)=-ptf(end).returnSimplePTF;
              

      
            membersLO=ptf(1).members;
            membersSO=ptf(end).members;
            weigthsLO=ptf(1).weigths;
            weigthsSO=ptf(end).weigths;
            members=[membersLO;membersSO];
            weigths=[weigthsLO;weigthsSO];
            labelLO_SO=[repmat('CompositionLO',size(membersLO,1),1);repmat('CompositionSO',size(membersSO,1),1)];
            
            if t==1
                matrixMember=table(repmat(strategieTable.Properties.VariableNames(s),size(members,1),1),repmat({ICtechnique},size(members,1),1),repmat(timeseries(t,:),size(members,1),1),labelLO_SO,members,weigths);
                
            else
                matrixMemberNew=table(repmat(strategieTable.Properties.VariableNames(s),size(members,1),1),repmat({ICtechnique},size(members,1),1),repmat(timeseries(t,:),size(members,1),1),labelLO_SO,members,weigths);
                matrixMember=[matrixMember;matrixMemberNew];
            end
            
            if t~=size(ref_data_legend,1)-learningTime-1
                clear ptf;
            end
        end
        leg_weigth=1; %quantity that fix weigth leg in LS ptf (1 or 0.5)
        isGrossEx=false;
        capitalLong=100;

        [results]=LongShort(bestReturnComp,shortRetSimple,bmk,capitalLong,leg_weigth,isGrossEx);
        
        [annualizedRetLO,annualizedVolLO,std_LO,meanLO,medianLO,SR_AR_AV_LO]=annualizedMetrics(bestReturnComp);
        [annualizedRetLS_Gross,annualizedVolLS_Gross,std_LS_Gross,meanLS_Gross,medianLS_Gross,SR_AR_AV_LS_Gross]=annualizedMetrics(results.puntret_LS_Gross);
        [annualizedRetLB_Gross,annualizedVolLB_Gross,std_LB_Gross,meanLB_Gross,medianLB_Gross,SR_AR_AV_LB_Gross]=annualizedMetrics(results.puntret_LB_Gross);
        [annualizedRetLS_Net,annualizedVolLS_Net,std_LS_Net,meanLS_Net,medianLS_Net,SR_AR_AV_LS_Net]=annualizedMetrics(results.puntret_LS_Net);
        [annualizedRetLB_Net,annualizedVolLB_Net,std_LB_Net,meanLB_Net,medianLB_Net,SR_AR_AV_LB_Net]=annualizedMetrics(results.puntret_LB_Net);
        % IR
        %         extrareturn=(bestReturnComp-bmk.totRet');
        %         [~,~,IR]=annualizedMetrics(extrareturn);
        matrix=[bestReturnComp;results.cumret_LO;shortRetSimple;results.cumret_SO;results.cumret_LS_Gross;results.cumret_LB_Gross;results.puntret_LS_Gross;results.puntret_LB_Gross;...
            results.cumret_LS_Net;results.cumret_LB_Net;results.puntret_LS_Net;results.puntret_LB_Net];
        
        if s==1&&tec==1
            outputMatrix=array2table(matrix);
            Returns={'puntretLO';'cumRetLO';'puntretSO';'cumRetSO';'cumRetLS_Gross';'cumRetLB_Gross';'puntretLS_Gross';'puntretLB_Gross';...
                         'cumRetLS_Net';'cumRetLB_Net';'puntretLS_Net';'puntretLB_Net'};
            Strategy=repmat(strategieTable.Properties.VariableNames(s),size(matrix,1),1);
            FactorWeights=repmat({ICtechnique},size(matrix,1),1);
            
            annualizedMetrixTable=table(strategieTable.Properties.VariableNames(s),{ICtechnique},results.cumret_LO(end),annualizedRetLO,annualizedVolLO,std_LO,meanLO,medianLO,SR_AR_AV_LO,...
                results.cumret_LS_Gross(end),annualizedRetLS_Gross,annualizedVolLS_Gross,std_LS_Gross,meanLS_Gross,medianLS_Gross,SR_AR_AV_LS_Gross,...
                results.cumret_LB_Gross(end),annualizedRetLB_Gross,annualizedVolLB_Gross,std_LB_Gross,meanLB_Gross,medianLB_Gross,SR_AR_AV_LB_Gross,...
                results.cumret_LS_Net(end),annualizedRetLS_Net,annualizedVolLS_Net,std_LS_Net,meanLS_Net,medianLS_Net,SR_AR_AV_LS_Net,...
                results.cumret_LB_Net(end),annualizedRetLB_Net,annualizedVolLB_Net,std_LB_Net,meanLB_Net,medianLB_Net,SR_AR_AV_LB_Net);
            annualizedMetrixTable.Properties.VariableNames(1:3)={'Strategies' 'IC technique' 'LO_CUMreturn_lastdate'};
            compoTable=matrixMember;
        else
            outputMatrix=[outputMatrix;array2table(matrix)];
            Returns=cat(1,Returns,{'puntretLO';'cumRetLO';'puntretSO';'cumRetSO';'cumRetLS_Gross';'cumRetLB_Gross';'puntretLS_Gross';'puntretLB_Gross';...
                         'cumRetLS_Net';'cumRetLB_Net';'puntretLS_Net';'puntretLB_Net'});
            Strategy=cat(1,Strategy,(repmat(strategieTable.Properties.VariableNames(s),size(matrix,1),1)));
            FactorWeights=cat(1,FactorWeights,(repmat({ICtechnique},size(matrix,1),1)));
            annualizedMetrixTable(end+1,:)={strategieTable.Properties.VariableNames(s),{ICtechnique},results.cumret_LO(end),annualizedRetLO,annualizedVolLO,std_LO,meanLO,medianLO,SR_AR_AV_LO,...
                results.cumret_LS_Gross(end),annualizedRetLS_Gross,annualizedVolLS_Gross,std_LS_Gross,meanLS_Gross,medianLS_Gross,SR_AR_AV_LS_Gross,...
                results.cumret_LB_Gross(end),annualizedRetLB_Gross,annualizedVolLB_Gross,std_LB_Gross,meanLB_Gross,medianLB_Gross,SR_AR_AV_LB_Gross,...
                results.cumret_LS_Net(end),annualizedRetLS_Net,annualizedVolLS_Net,std_LS_Net,meanLS_Net,medianLS_Net,SR_AR_AV_LS_Net,...
                results.cumret_LB_Net(end),annualizedRetLB_Net,annualizedVolLB_Net,std_LB_Net,meanLB_Net,medianLB_Net,SR_AR_AV_LB_Net};
            compoTable=[compoTable;matrixMember];
        end
        clear matrix
        clear matrixMember
        clear membersLO
        clear membersSO
        clear weigthsSO
        clear weigthsLO
    end
end

toc
compoTable.Properties.VariableNames={'Strategies', 'FactorWeights', 'Date','LongOnly/ShortOnly', 'Members', 'Weights'};

outputMatrix(end+1,:)= array2table(bmk.totRet');
outputMatrix(end+1,:)= array2table(bmk.cumRet);
outputMatrix.Properties.VariableNames=cellstr(char(timeseries));
Returns{end+1}='puntretLO';
Returns{end+1}='cumRetLO';
Returns=cell2table(Returns);
Returns.Properties.VariableNames={'Returns'};
Strategy{end+1}='BMK';
Strategy{end+1}='BMK';
Strategy=cell2table(Strategy);
Strategy.Properties.VariableNames={'Strategy'};
FactorWeights{end+1}='BMK';
FactorWeights{end+1}='BMK';
FactorWeights=cell2table(FactorWeights);
FactorWeights.Properties.VariableNames={'FactorWeights'};
OutputTable=[Strategy FactorWeights Returns outputMatrix];

[annualizedRetBMK,annualizedVolBMK,std_BMK,meanBMK,medianBMK,SR_AR_AV_BMK]=annualizedMetrics(bmk.totRet');
BMKMatrics={'BMK','BMK',bmk.cumRet(end), annualizedRetBMK,annualizedVolBMK,std_BMK,meanBMK,medianBMK,SR_AR_AV_BMK};


if length(ICtechniqueVec)==3
teclabel='.xlsx';
elseif strcmp(ICtechniqueVec,'MovingAverage3M')
teclabel='_MA.xlsx';
elseif strcmp(ICtechniqueVec,'FixedWeights')
teclabel='_FixedW.xlsx';
elseif strcmp(ICtechniqueVec,'Rolling36M')
teclabel='_RW.xlsx';
end

filename=strcat(outputpath,'Allstrategies',teclabel);


writetable(OutputTable,filename,'Sheet','AllStrategies');
writetable(annualizedMetrixTable,filename,'Sheet','Metrics');
writecell(BMKMatrics,filename,'Sheet','Metrics','Range',strcat('A',num2str(size(annualizedMetrixTable,1))));

writetable(compoTable,strcat(outputpath,'StrategiesCompositions',teclabel),'Sheet','Compositions');



% historicalIC=historicalIC(ICmap,learningTime,meanlag,legendaICB,ref_data_learning);
% filename = 'IC_completo.xlsx';
%     for i=1:length(legendaICB)
%         label=strcat('ICB','_',num2str(legendaICB(i,1)));
%         histIC=historicalIC{i};
%         ic{i}=histIC(:,col);
%         writematrix(ic{i},filename,'Sheet',label ,'Range','D2')
%     end






