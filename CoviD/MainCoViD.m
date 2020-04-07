clc, clear all, close all

datadead = readtable("comune_giorno.csv");
datadead.GE = datadead.GE + 20200000;

%% get Bergamo Prov. data without not available data
dataBg = datadead((datadead.PROV == 16 & datadead.TOTALE_20~=9999),:); 

% aggregate 
dataBG_byComune = varfun(@sum, dataBg,'InputVariables',{'TOTALE_15','TOTALE_16',...
                               'TOTALE_17','TOTALE_18','TOTALE_19','TOTALE_20'},...
                               'GroupingVariables',{'NOME_COMUNE','COD_PROVCOM','GE'});

dataBG_byComune_avg = dataBG_byComune(:,1:3);
dataBG_byComune_avg.MEDIA_15_19 = mean(dataBG_byComune{:,5:9},2);
dataBG_byComune_avg.TOTALE_20 = dataBG_byComune.sum_TOTALE_20;

dataProvincia = varfun(@sum, dataBG_byComune_avg,'InputVariables',{'MEDIA_15_19','TOTALE_20'},...
                               'GroupingVariables','GE');
                           
%% elaborate data                          
xdata = 1:1:numel(dataProvincia.sum_MEDIA_15_19); 
xdatetime = unique(datenum(num2str(dataBG_byComune_avg.GE),'yyyymmdd'));

FitTbl_avg = table(xdata',dataProvincia.sum_MEDIA_15_19);

Model_avg = fitlm(FitTbl_avg);
fittedline_avg = Model_avg.Coefficients.Estimate(1)+Model_avg.Coefficients.Estimate(2)*xdata';

FitTbl_cvd = table(xdata',dataProvincia.sum_TOTALE_20-fittedline_avg); 

modelfun = @(b,x) b(3)*(exp(-(x(:, 1)-b(1))/b(2))./(b(2).*(1+exp(-(x(:, 1)-b(1))/b(2))).^2)); 
beta0 = [80, 4, 2000]; % Guess values to start with. 
Model_cvd = fitnlm(FitTbl_cvd, modelfun, beta0);

b0 = Model_cvd.Coefficients{:, 'Estimate'};
% Create smoothed/regressed data using the model:
% yFitted = coefficients(1) + coefficients(2) * exp(-coefficients(3)*xdata');
yFitted = modelfun(b0,xdata') + fittedline_avg;

b1 = b0 + 5*Model_cvd.Coefficients{:, 'SE'};
yFitted1 = modelfun(b1,xdata') + fittedline_avg;

b2 = b0 - 5*Model_cvd.Coefficients{:, 'SE'};
yFitted2 = modelfun(b2,xdata') + fittedline_avg;

%% plot
f1 = figure();  
hold on;
p1 = plot(dataProvincia.sum_MEDIA_15_19,'DisplayName','dataProvincia.sum_MEDIA_15_19');
p1.LineStyle = 'none';
p1.Marker = 'o';
p1.MarkerSize = 4;
p1.Color = [0,0,1];
p3 = plot(fittedline_avg,'DisplayName','Media_fitted');
p3.Color = [0,0,1];
p2 = plot(dataProvincia.sum_TOTALE_20,'DisplayName','dataProvincia.sum_TOTALE_20');
p2.LineStyle = 'none';
p2.Marker = 'd';
p2.MarkerSize = 4;
p4 = plot(yFitted,'DisplayName','COVID_fitted');
p4.Color = [1,0,0];
p4 = plot(yFitted1,'DisplayName','COVID_fitted_SE+');
p4.Color = [0,1,0];
p4 = plot(yFitted2,'DisplayName','COVID_fitted_SE-');
p4.Color = [0,1,0];
hold off;
                        
%% numero contagiati
letalIndex = [1/0.0051 1/0.0114 1/0.0178];

stimacontagio = cumsum(FitTbl_cvd{:,2}*letalIndex);
stimacontagio(stimacontagio<0)=0;

f2 = figure();  
hold on;
p21 = plot(stimacontagio(:,1),'DisplayName','contagioMax');
p21.LineStyle = 'none';
p21.Marker = 'o';
p21.MarkerSize = 3;
p21.Color = [0,0,1];
p22 = plot(stimacontagio(:,2),'DisplayName','contagio');
p22.LineStyle = 'none';
p22.Marker = 'd';
p22.MarkerSize = 4;
p22.Color = [1,0,0];
p23 = plot(stimacontagio(:,3),'DisplayName','contagioMin');
p23.LineStyle = 'none';
p23.Marker = 'o';
p23.MarkerSize = 3;
p23.Color = [0,0,1];
                           