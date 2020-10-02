clc
clear all
close

userId = getenv('USERNAME');
addpath(['C:\Users\',userId,'\Desktop\EFI\CODE\input']);
addpath(['C:\Users\',userId,'\Desktop\EFI\CODE\input\anagrafiche']);
outputpath= 'C:\Users\u369343\Desktop\EFI\CODE\output\FMP\';

reducedRF=[0 1]; %boolean variable to define if calendar is constract on the entire or reduced set of riskfactors.
risk32=readtable('rf2supergroup.xlsx','Sheet','rf32');

startdate=datetime(2005,04,29);

%% create rf2gruop map
rf2gruopTable=readtable('rf2supergroup.xlsx');
rf=rf2gruopTable.RF;
supergroup=rf2gruopTable.SUPER_GROUP;
rf2superGroup=containers.Map(rf,supergroup);

for r=1:length(reducedRF)

    if reducedRF(r)==1
        reduceLabel='_32rf.xlsx';
    else
        reduceLabel='.xlsx';
    end
    fmp=readFMP('FMP.xlsx',reducedRF(r),risk32);
    
    %create dates
    t=dateshift(startdate,'end','month',0:size(fmp.longOnly,2)-1);
    for i=1:length(t)
        if isbusday(t(i))~=1
           t(i)=busdate(t(i),-1);
        end      
    end

    for col=2:size(fmp.longOnly,2) %because col 1 is zeros
        maxValueLO(col,1)=max(fmp.longOnly(:,col));
        indexmaxLO=find(fmp.longOnly(:,col)==maxValueLO(col));
        maxrfLO{col,1}=fmp.rf{indexmaxLO};
        superGrouprfmaxLO{col,1}=rf2superGroup(char(maxrfLO{col,1}));
        minValueLO(col,1)=min(fmp.longOnly(:,col));
        indexminLO=find(fmp.longOnly(:,col)==minValueLO(col));
        minrfLO{col,1}=fmp.rf{indexminLO};
        superGrouprfminLO{col,1}=rf2superGroup(char(minrfLO{col,1}));
        
        maxValueLS(col,1)=max(fmp.ls(:,col));
        indexmaxLS=find(fmp.ls(:,col)==maxValueLS(col));
        maxrfLS{col,1}=fmp.rf{indexmaxLS};
        superGrouprfmaxLS{col,1}=rf2superGroup(char(maxrfLS{col,1}));
        minValueLS(col,1)=min(fmp.ls(:,col));
        indexminLS=find(fmp.ls(:,col)==minValueLS(col));
        minrfLS{col,1}=fmp.rf{indexminLS};
        superGrouprfminLS{col,1}=rf2superGroup(char(minrfLS{col,1}));
    end
    outputLO=table(t',maxrfLO,maxValueLO,superGrouprfmaxLO,minrfLO,minValueLO,superGrouprfminLO);
    outputLS=table(t',maxrfLS,maxValueLS,superGrouprfmaxLS,minrfLS,minValueLS,superGrouprfminLS);
    writetable(outputLO,strcat(outputpath,'calendario',reduceLabel),'Sheet','LO')
    writetable(outputLS,strcat(outputpath,'calendario',reduceLabel),'Sheet','LS')
end

