% test GetArtificialPrices

clear all; close all; clc

sample_prices = GetArtificialPrices();

figure();
plot(sample_prices.sample_date,sample_prices.prices);

params.prices = sample_prices; %timeseries
params.std_price_window = 63;
params.std_MACD_window = 252;
params.movav_short = 8;
params.movav_long = 24;
params.size_exp_div = 0.89;

TrendEst = MACD_trend_estimator(params);
[trend_est, pos_size] = MACD_trend_and_size(params);

test = (-10:0.1:10);
testphi = (1/params.size_exp_div).*test.*exp((-test.^2)/4);