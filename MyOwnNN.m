%%% MY NETWORK TEST
% neural network to filter or predict a timeseries with seasonality, arma
% and garch components
clear all, close all, clc

% create the database

numb_of_TS = 100;
my_prices = cell(numb_of_TS,1);

tic
for i = 1:numb_of_TS
   sample = GetArtificialPrices(); 
   my_prices{i} = sample.prices;
end
toc
%%
layers = [
    sequenceInputLayer(1,"Name","sequence")
    fullyConnectedLayer(10,"Name","fc")
    lstmLayer(128,"Name","lstm_1")
    lstmLayer(128,"Name","lstm_2")
    reluLayer("Name","relu")
    regressionLayer("Name","regressionoutput")];