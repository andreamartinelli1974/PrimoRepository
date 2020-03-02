%%% MY NETWORK TEST
% neural network to filter or predict a timeseries with seasonality, arma
% and garch components
clear all, close all, clc

% create the database

train_pct= 0.6;
validation_pct = 0.2;
sample = GetArtificialPrices();
rolling_window = 252;
delta = 10;

params.prices = sample; %timeseries
params.std_price_window = 63;
params.std_MACD_window = 252;
params.movav_short = 8;
params.movav_long = 24;
params.size_exp_div = 0.89;

TrendEst = MACD_trend_estimator(params);
[trend_est, pos_size] = MACD_trend_and_size(params);

t_up1 = prctile(trend_est.data,95);
t_up2 = prctile(trend_est.data,99);
t_dw1 = prctile(trend_est.data,5);
t_dw2 = prctile(trend_est.data,1);
trend_est_category = zeros(numel(trend_est.data),1);

for i = 1:numel(trend_est.data)
    data = trend_est.data(i);
    if data >= t_up2
        trend_est_category(i) = 2;
    elseif data > t_up1
        trend_est_category(i) = 1;
    elseif data <= t_dw2
        trend_est_category(i) = -2;
    elseif data <= t_dw1
        trend_est_category(i) = -1;
    end
end

trend_est_category = categorical(trend_est_category);

numTimeStepsTrain = round(numel(sample.prices)*train_pct);
numTimeStepsValid = round(numel(sample.prices)*validation_pct);
train_prices = sample.prices(1:numTimeStepsTrain);
validation_prices = sample.prices(numTimeStepsTrain+1:numTimeStepsTrain+numTimeStepsValid);
test_prices = sample.prices(numTimeStepsTrain+numTimeStepsValid+1:end);

trend_est_train = trend_est_category(1:numTimeStepsTrain);
trend_est_valid = trend_est_category(numTimeStepsTrain+1:numTimeStepsTrain+numTimeStepsValid);
trend_est_test  = trend_est_category(numTimeStepsTrain+numTimeStepsValid+1:end);

%% normalization
mu = mean(train_prices);
sig = std(train_prices);
% mu = 0;
% sig = 1;

train_prices_norm = (train_prices - mu) / sig;
validation_prices_norm = (validation_prices - mu) /sig;
test_prices_norm = (test_prices - mu) / sig;

% train_prices_norm = tanh(train_prices);
% validation_prices_norm = tanh(validation_prices);
% test_prices_norm = tanh(test_prices);

%% prepare data

% set up the cell array
my_prices = cell(numTimeStepsTrain-rolling_window-delta,1);
my_truth = cell(numTimeStepsTrain-rolling_window-delta,1);

my_valid_x = cell(numTimeStepsValid-rolling_window);
my_valid_y = cell(numTimeStepsValid-rolling_window);

my_test = cell(numel(test_prices_norm)-rolling_window-delta,1);
my_test_truth = cell(numel(test_prices_norm)-rolling_window-delta,1);

% fill the array with data
for i = 1:numTimeStepsTrain-rolling_window-delta
    my_prices{i} = train_prices_norm(i:i+rolling_window-1)';
    my_truth{i} = train_prices_norm(i+delta:i+rolling_window+delta-1)';
end
for i = 1:numTimeStepsValid-rolling_window
    my_valid_x{i} = validation_prices_norm(i:i+rolling_window-2)';
    my_valid_y{i} = validation_prices_norm(i+1:i+rolling_window-1)';
end
for i = 1: numel(test_prices_norm)-rolling_window-delta
    my_test{i} = test_prices_norm(i:i+rolling_window-2)';
    my_test_truth{i} = test_prices_norm(i+delta:i+rolling_window+delta-1)';
end


%%

% options = trainingOptions('adam', ...
%     'MaxEpochs',250, ...
%     'GradientThreshold',1, ...
%     'InitialLearnRate',0.005, ...
%     'LearnRateSchedule','piecewise', ...
%     'LearnRateDropPeriod',125, ...
%     'LearnRateDropFactor',0.2, ...
%     'Verbose',0, ...
%     'Plots','training-progress');
% 
% %     'ValidationData',{my_valid_x,my_valid_y}, ...
% %     'ValidationFrequency',1, ...
% %     'ValidationPatience',5, ...

% maxEpochs = 100;
% miniBatchSize = 27;
% 
% options = trainingOptions('adam', ...
%     'ExecutionEnvironment','cpu', ...
%     'GradientThreshold',1, ...
%     'MaxEpochs',maxEpochs, ...
%     'MiniBatchSize',miniBatchSize, ...
%     'SequenceLength','longest', ...
%     'Shuffle','never', ...
%     'Verbose',0, ...
%     'Plots','training-progress');

maxEpochs = 15;
miniBatchSize = 20;

options = trainingOptions('adam', ...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize, ...
    'InitialLearnRate',0.01, ...
    'GradientThreshold',1, ...
    'Shuffle','never', ...
    'Plots','training-progress',...
    'Verbose',0);

numResponses = size(my_truth{1},1);
featureDimension = size(my_prices{1},1);
numHiddenUnits = 200;

layers = [ ...
    sequenceInputLayer(featureDimension)
    lstmLayer(numHiddenUnits,'OutputMode','sequence')
    fullyConnectedLayer(50)
    dropoutLayer(0.5)
    fullyConnectedLayer(numResponses)
    regressionLayer];

net = trainNetwork(my_prices,my_truth,layers,options);

%%

my_pred = predict(net,my_test);
data = zeros(numel(my_test)+delta,1);
pred = zeros(numel(my_test)+delta,1);;

for i = 1:numel(my_test)
    data(i) = my_test{i}(end);
    pred(i+delta) = my_pred{i}(end);
end


%%

figure
plot(data)
hold on
plot(pred)
hold off

