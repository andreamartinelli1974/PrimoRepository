clc, clear all, close all

mov_av = 1;

datadead = readtable("comune_giorno.csv");
datadead.GE = datadead.GE + 20200000;

%% get Bergamo Prov. data without not available data
dataBG = datadead((datadead.PROV == 16),:); 
% dataBG = datadead; 

% aggregate 
dataBG_byComune_avg_all = varfun(@sum, dataBG,'InputVariables',{'TOTALE_15','TOTALE_16',...
                               'TOTALE_17','TOTALE_18','TOTALE_19'},...
                               'GroupingVariables',{'NOME_COMUNE','COD_PROVCOM','GE'});

dataBG_20 = dataBG(dataBG.TOTALE_20 ~= 9999,:);                         
dataBG_byComune_20_all = varfun(@sum, dataBG_20,'InputVariables','TOTALE_20',...
                               'GroupingVariables',{'NOME_COMUNE','COD_PROVCOM','GE'});


common_provcom = intersect(dataBG_byComune_avg_all.COD_PROVCOM,dataBG_byComune_20_all.COD_PROVCOM);

dataBG_byComune_avg = [];
dataBG_byComune_20 = [];

for i = 1:numel(common_provcom)
    dataBG_byComune_avg = [dataBG_byComune_avg; ...
        dataBG_byComune_avg_all(dataBG_byComune_avg_all.COD_PROVCOM == common_provcom(i),:)];
    
    dataBG_byComune_20 = [dataBG_byComune_20; ...
        dataBG_byComune_20_all(dataBG_byComune_20_all.COD_PROVCOM == common_provcom(i),:)];
end

dataBG_byComune_avg.MEDIA_15_19 = mean(dataBG_byComune_avg{:,5:9},2);

dataProvincia = varfun(@sum, dataBG_byComune_avg,'InputVariables',{'MEDIA_15_19'},...
    'GroupingVariables','GE');
dataProvincia_20 = varfun(@sum, dataBG_byComune_20,'InputVariables',{'sum_TOTALE_20'},...
    'GroupingVariables','GE');

tbl = varfun(@sum, dataBG_byComune_avg,'InputVariables',{'sum_TOTALE_15'},...
    'GroupingVariables','GE');
dataProvincia.M15 = tbl.sum_sum_TOTALE_15;
tbl = varfun(@sum, dataBG_byComune_avg,'InputVariables',{'sum_TOTALE_16'},...
    'GroupingVariables','GE');
dataProvincia.M16 = tbl.sum_sum_TOTALE_16;
tbl = varfun(@sum, dataBG_byComune_avg,'InputVariables',{'sum_TOTALE_17'},...
    'GroupingVariables','GE');
dataProvincia.M17 = tbl.sum_sum_TOTALE_17;
tbl = varfun(@sum, dataBG_byComune_avg,'InputVariables',{'sum_TOTALE_18'},...
    'GroupingVariables','GE');
dataProvincia.M18 = tbl.sum_sum_TOTALE_18;
tbl = varfun(@sum, dataBG_byComune_avg,'InputVariables',{'sum_TOTALE_19'},...
    'GroupingVariables','GE');
dataProvincia.M19 = tbl.sum_sum_TOTALE_19;


dataProvincia.sum_MEDIA_15_19 = dataProvincia.M19;

%% get moving average data
if mov_av == 1
    steps = [2,0];
    dataProvincia_20.sum_sum_TOTALE_20 = movmean(dataProvincia_20.sum_sum_TOTALE_20,steps);
    dataProvincia.sum_MEDIA_15_19 = movmean(dataProvincia.sum_MEDIA_15_19,steps);
    dataProvincia.M15 = movmean(dataProvincia.M15,steps);
    dataProvincia.M16 = movmean(dataProvincia.M16,steps);
    dataProvincia.M17 = movmean(dataProvincia.M17,steps);
    dataProvincia.M18 = movmean(dataProvincia.M18,steps);
    dataProvincia.M19 = movmean(dataProvincia.M19,steps);
end


%% elaborate data                          
xdate = unique(datenum(num2str(dataBG_byComune_avg.GE),'yyyymmdd'));
xdatetime = datetime(xdate,'ConvertFrom','datenum');

xdate20 = unique(datenum(num2str(dataBG_byComune_20.GE),'yyyymmdd'));
xdatetime20 = datetime(xdate20,'ConvertFrom','datenum');

FitTbl_avg = table(xdate,dataProvincia.sum_MEDIA_15_19);
FitTbl_cvd_baseline = table(xdate20(1:51),dataProvincia_20.sum_sum_TOTALE_20(1:51));

Model_avg = fitlm(FitTbl_avg,'quadratic');
a0 = Model_avg.Coefficients.Estimate;
modelfun_avg = @(b,x) b(1)+b(2)*x+b(3)*x.^2;

Model_cvd_baseline = fitlm(FitTbl_cvd_baseline);
c0 = Model_cvd_baseline.Coefficients.Estimate;
FittedAVG = table(xdatetime,dataProvincia.sum_MEDIA_15_19,modelfun_avg(a0,xdate),c0(1)+c0(2)*xdate);

[dates_20,index_avg,index_20] = intersect(xdatetime,xdatetime20);
FitTbl_cvd = table(xdate20-xdate20(1),dataProvincia_20.sum_sum_TOTALE_20-FittedAVG.Var4(index_avg)); 

modelfun = @(b,x) b(3)*(exp(-(x(:, 1)-b(1))/b(2))./(b(2).*(1+exp(-(x(:, 1)-b(1))/b(2))).^2)); 
beta0 = [80, 4, 2000]; % Guess values to start with. 
Model_cvd = fitnlm(FitTbl_cvd, modelfun, beta0);

b0 = Model_cvd.Coefficients{:, 'Estimate'};
% Create smoothed/regressed data using the model:
% yFitted = coefficients(1) + coefficients(2) * exp(-coefficients(3)*xdata');
FittedCVD = table(xdatetime20,dataProvincia_20.sum_sum_TOTALE_20,...
                modelfun(b0,xdate20-xdate20(1)) + FittedAVG.Var4(index_avg));
            
FittedCVD.Properties.VariableNames = {'xdatetime20','CoviD','Fitted_CoviD'};

b1 = b0 + 5*Model_cvd.Coefficients{:, 'SE'};
FittedCVD.SE1 = modelfun(b1,xdate20-xdate20(1)) + FittedAVG.Var4(index_avg);

b2 = b0 - 5*Model_cvd.Coefficients{:, 'SE'};
FittedCVD.SE2 = modelfun(b2,xdate20-xdate20(1)) + FittedAVG.Var4(index_avg);

[C, diffDate] = setdiff(xdatetime,xdatetime20);
diffDate = [diffDate(1)-1; diffDate];
PreviewCVD = table(xdatetime(diffDate),...
                   modelfun(b0,xdate(diffDate)-xdate20(1)) + FittedAVG.Var4(diffDate),...
                   modelfun(b1,xdate(diffDate)-xdate20(1)) + FittedAVG.Var4(diffDate),...
                   modelfun(b2,xdate(diffDate)-xdate20(1)) + FittedAVG.Var4(diffDate));
               
PreviewCVD.Properties.VariableNames = {'xdatetime','Fitted_CoviD','SE1','SE2'};

%% plot

f1 = figure();  
hold on;
% plot baseline with fitted line
p1 = plot(FittedAVG.xdatetime,FittedAVG.Var2,'DisplayName','Mortalit� 19');
p1.LineStyle = 'none';
p1.Marker = 'o';
p1.MarkerSize = 4;
p1.Color = [0,0,1];
% p3 = plot(FittedAVG.xdatetime,FittedAVG.Var3,'DisplayName','Media fitted');
% p3.Color = [0,0,1];

% plot CoviD with Fitted Line 
p2 = plot(FittedCVD.xdatetime20,FittedCVD.CoviD,'DisplayName','CoviD');
p2.LineStyle = 'none';
p2.Marker = 'd';
p2.MarkerSize = 4;
p2.Color = [1,0,0];
p4 = plot(FittedCVD.xdatetime20,FittedCVD.Fitted_CoviD,'DisplayName','CoviD fitted');
p4.Color = [1,0,0];
p4.LineWidth = 1;
p5 = plot(FittedCVD.xdatetime20,FittedCVD.SE1,'DisplayName','CoviD fitted SE+');
%p5.LineStyle = '--';
p5.Color = [0.8500 0.3250 0.0980];
p6 = plot(FittedCVD.xdatetime20,FittedCVD.SE2,'DisplayName','CoviD fitted SE-');
%p6.LineStyle = '--';
p6.Color = [0.9290 0.6940 0.1250];

% plot fitted previews
p7 = plot(PreviewCVD.xdatetime,PreviewCVD.Fitted_CoviD,'DisplayName','CoviD fitted');
p7.Color = [0.4660 0.6740 0.1880];
p7.LineWidth = 1;
p8 = plot(PreviewCVD.xdatetime,PreviewCVD.SE1,'DisplayName','');
p8.LineStyle = '--';
p8.Color = [0.8500 0.3250 0.0980];
p9 = plot(PreviewCVD.xdatetime,PreviewCVD.SE2,'DisplayName','');
p9.LineStyle = '--';
p9.Color = [0.9290 0.6940 0.1250];

legend
hold off;
                        
%% numero contagiati
letalIndex = [1/0.0051 1/0.0114 1/0.0178];

stimacontagio = cumsum(FitTbl_cvd{52:end,2}*letalIndex);
stimacontagio(stimacontagio<0)=0;
date = xdatetime20(52:end,1);

f2 = figure();
p21 = semilogy(date,stimacontagio(:,1),'DisplayName','contagioMax');
hold on;
p21.LineStyle = 'none';
p21.Marker = 'o';
p21.MarkerSize = 3;
p21.Color = [0,0,1];
p22 = semilogy(date,stimacontagio(:,2),'DisplayName','contagio');
p22.LineStyle = 'none';
p22.Marker = 'd';
p22.MarkerSize = 4;
p22.Color = [1,0,0];
p23 = semilogy(date,stimacontagio(:,3),'DisplayName','contagioMin');
p23.LineStyle = 'none';
p23.Marker = 'o';
p23.MarkerSize = 3;
p23.Color = [0,0,1];
hold off;

%% plot deads for any year

figure();
h1=plot(xdatetime,dataProvincia.M15,'LineStyle','none','Marker','o');
set(h1, 'markerfacecolor', get(h1, 'color'));
h1.MarkerSize = 3;
hold on;
h2=plot(xdatetime,dataProvincia.M16,'LineStyle','none','Marker','o');
set(h2, 'markerfacecolor', get(h2, 'color'));
h2.MarkerSize = 3;
h3=plot(xdatetime,dataProvincia.M17,'LineStyle','none','Marker','o');
set(h3, 'markerfacecolor', get(h3, 'color'));
h3.MarkerSize = 3;
h4=plot(xdatetime,dataProvincia.M18,'LineStyle','none','Marker','o');
set(h4, 'markerfacecolor', get(h4, 'color'));
h4.MarkerSize = 3;
h5=plot(xdatetime,dataProvincia.M19,'LineStyle','none','Marker','o');
set(h5, 'markerfacecolor', get(h5, 'color'));
h5.MarkerSize = 3;
h6=plot(xdatetime20,dataProvincia_20.sum_sum_TOTALE_20,'LineStyle','none','Marker','o');
set(h6, 'markerfacecolor', get(h6, 'color'));
h6.MarkerSize = 3;
hold off;



                           