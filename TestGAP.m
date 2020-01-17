% test GetArtificialPrices

clear all; close all; clc

sample_prices = GetArtificialPrices();

figure();
plot(sample_prices.sample_date,sample_prices.prices);