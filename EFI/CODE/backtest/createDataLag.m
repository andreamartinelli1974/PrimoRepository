
function [LAGdataSandwich,sedolClean,mapTimeSlice,startDate,endDate,cardTimeSlice]=createDataLag(sandwichData,sedolchkTot,ref_data_legend,cardCompaniesbyDate,lag)

%% Input:
%sadwichData
%sedolchkTot: array that show all the sedols in the sandwichData.
%             Length(sedolchkTot)= number of rows in sandwichData
%ref_data_legend: array that contains all the ref_date involved in
%                 sandwichData.
%cardCompaniesByDate: array that contains number of sedols at each data
%lag: number of months between rf e cumulative returns 

%OUTPUT: 
%LAGdataSandwich: sandwichData that associate rf with return cumulated
%                   during lag-months. 
%sedolClean: list of sedol in LAGdataSandwich
%mapTimeSlice: map that associate at each time the respective timeSlice
%startdate: vector that contains dates that refer to rf and from which cumulative returns
%           are calcultate from.
%endDate: dates that corrispond to the final date for cumative returns.
%cardTimeSlice: number of companies at each timeslice 

%FUNCTION:
%a new datasandwich is created:relations between rf at time t and
%returns at time t+lag would be ana. So, in the new dataset the
%timeslice at time t displays rf at time t and cum return calculated in
%[t,t+35].


startpoint=1;
for t=1:size(ref_data_legend,1)-lag+1
    count=1;% count for sedols that have to be deleted(we delete sedols died in [t,t+35])
    startDate(t)=ref_data_legend(t);
    endDate(t)=ref_data_legend(t+lag-1);
    endpoint=startpoint+sum(cardCompaniesbyDate(t:t+lag-1))-1;% position of the last element of timeslice t+36
    sandwichDataLag=sandwichData(startpoint:endpoint,:); %data used to calculate cum return
    
    
    sedolchkLag= sedolchkTot(startpoint:endpoint);
    sedolchkStartDate=sedolchkLag(1:cardCompaniesbyDate(t),1);% sedols involved in the first timeslice of the sandwich
    sandwichRetLag=sandwichDataLag(:,2:3);%retuns involved in cum retor calcultation. contain at each row returns of each company
    timeSlice=sandwichDataLag(1:cardCompaniesbyDate(t),:); 
   
    retCumSimp=zeros(cardCompaniesbyDate(t),1);
    retCumComp=zeros(cardCompaniesbyDate(t),1);
    
    for s=1:length(sedolchkStartDate)
        if strcmp(sedolchkStartDate{s},'673123') ||strcmp(sedolchkStartDate{s},'575809')
           x=eccolo;
        end
        index_sedol=find(strcmp(sedolchkLag,sedolchkStartDate{s})); %extract in [t,t+36] data that refere to the s-th seldol
        if length(index_sedol)~=lag %if the s-th sedol appers less than lag time it means that is dead in the meanwhile
            deletedCompany{count}=sedolchkStartDate{s};
            index_eliminati(count)=index_sedol(1);
            count=count+1;%it means that during these months the company has been deleted
            continue; %change sedol
        end
        returnSimpleSedol=sandwichRetLag(index_sedol,1); %simple returns that refere to the s-th sedol
        returnCompSedol=sandwichRetLag(index_sedol,2);
        capitalSimple(1)=100; %capital initial point
        capitalComp(1)=100;
        for j=2:lag+1
            capitalSimple(j)=capitalSimple(j-1)*(1+returnSimpleSedol(j-1));%capital evolution between [t,t+lag]
            capitalComp(j)=capitalComp(j-1)*(1+returnCompSedol(j-1));
        end
        retCumSimp(s,1)=(capitalSimple(end)-capitalSimple(1))/capitalSimple(1); %cum return of the s-th sedol after lag-months
        retCumComp(s,1)=(capitalComp(end)-capitalComp(1))/capitalComp(1);
        if s==1
            sedolRetSimpMap=containers.Map(sedolchkStartDate{s},retCumSimp(s));
            sedolRetCompMap=containers.Map(sedolchkStartDate{s},retCumComp(s));
        else
            sedolRetSimpMap(sedolchkStartDate{s})=retCumSimp(s);
            sedolRetCompMap(sedolchkStartDate{s})=retCumSimp(s);
        end
    end
    
    %substitude puntual return with cumRet after lag- months
    timeSlice(:,2)=retCumSimp;
    timeSlice(:,3)=retCumComp;
    
    % take off from timeslice deleted sedols
    timeSlice(index_eliminati,:)=[];
    sedolchkStartDate(index_eliminati,:)=[];
    if t==1
        LAGdataSandwich=timeSlice;
        sedolClean=sedolchkStartDate;
        mapTimeSlice=containers.Map(t,timeSlice);
       
    else
        LAGdataSandwich=[LAGdataSandwich;timeSlice];
        sedolClean=[sedolClean;sedolchkStartDate];
        mapTimeSlice(t)=timeSlice;
    end
    cardTimeSlice(t)=size(mapTimeSlice(t),1); %count the number of companies involved
    startpoint=startpoint+cardCompaniesbyDate(t);%chanhe timeslice
    clear index_eliminati;
    clear retCumSimp;
    clear retCumComp;
end
end
    





