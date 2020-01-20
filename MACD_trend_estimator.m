function output = MACD_trend_estimator(params)
    % function to estimate the trend of a price series using a
    % volatility-normalized function based on exponential moving averages
    % on short an long period. 
    % the function is needed to calculate the investment size of a position
    % depending from the strenght of the signal
    % see Lim. Zohren, Roberts 2019, formula (4) and following
    
    prices = params.prices; %timeseries
    std_price_window = params.std_price_window;
    std_MACD_window = params.std_MACD_window;
    movavg_short_wndw = params.movav_short;
    movavg_long_wndw = params.movav_long;
    
    no_prices = size(prices,1);
    
    if no_prices> std_MACD_window && no_prices> std_price_window
        for k = 1:no_prices-std_MACD_window
            
        
    elseif no_prices<= std_MACD_window
        disp('ERROR: std_MACD_window is longer then price history');
    elseif no_prices<= std_price_window
        disp('ERROR: std_price_window is longer then price history');
    end
    std_prices = std(prices(end-std_roll_window:end);
    
    movavg_short = movavg(prices,'exponential',movavg_short_wndw);
    movavg_long = movavg(prices,'exponential',movavg_long_wndw);
    
    macd = movavg_short - movavg_long;

end