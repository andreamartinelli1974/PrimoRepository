function [trend_est, pos_size] = MACD_trend_and_size(params)
    % function to estimate the trend and size of a price series using a
    % volatility-normalized function based on exponential moving averages
    % on short an long period. 
    % the function is needed to calculate the investment size of a position
    % depending from the strenght of the signal
    % see Lim. Zohren, Roberts 2019, formula (4) and following
    
    % input parameters
    prices = params.prices; %timeseries
    date = prices.sample_date;
    std_price_window = params.std_price_window;
    std_MACD_window = params.std_MACD_window;
    movavg_short_wndw = params.movav_short;
    movavg_long_wndw = params.movav_long;
    size_exp_div = params.size_exp_div;
    
    % variable definition
    no_prices = size(prices,1);
    data = zeros(no_prices,1);
    std_prices = timetable(date,data);
    norm_MACD  = timetable(date,data);
    trend_est  = timetable(date,data);
    pos_size   = timetable(date,data);
    
    
    if no_prices> std_price_window && no_prices> std_MACD_window
        
        movavg_short = movavg(prices.prices,'exponential',movavg_short_wndw);
        movavg_long = movavg(prices.prices,'exponential',movavg_long_wndw);
        MACD = movavg_short - movavg_long;
        
        for t = std_price_window:no_prices
            std_prices.data(t) = std(prices.prices(t-std_price_window+1:t));
            norm_MACD.data(t) = MACD(t)/std_prices.data(t);
        end
        for t = std_MACD_window:no_prices
            trend_est.data(t) = norm_MACD.data(t)/std(norm_MACD.data(t-std_price_window+1:t));
        end
        
    elseif no_prices<= std_MACD_window
        disp('ERROR: std_MACD_window is longer then price history');
    elseif no_prices<= std_price_window
        disp('ERROR: std_price_window is longer then price history');
    end
    
    pos_size.data = (1/size_exp_div).*trend_est.data.*exp((-trend_est.data.^2)/4);
end

