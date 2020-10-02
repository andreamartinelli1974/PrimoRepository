function [annulizedRet,annualizedVol,standardDev,media,mediana,SR_AR_AV]=annualizedMetrics(serie)

%%INPUT:
%serie: time serie of cumulative returns that has as first element zero

%OUTPUT:
%Annalized return, Annualized standard deviation, Sharpe
productRet=prod(1+ serie(2:end)); %starts form 2 beacuse the first is zero
annulizedRet=-1+(productRet^(12/(length(serie)-1)));
annualizedVol=sqrt(12)*std(serie(2:end));
standardDev= std(serie(2:end));
mediana=median(serie(2:end));
media=mean(serie(2:end));
SR_AR_AV=annulizedRet/annualizedVol;

end