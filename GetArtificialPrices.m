function PriceSample = GetArtificialPrices()
% to produce simulated asset prices with stagionality, autodependancy and
% so on to train and test a NN 
% code translated from python %

    % Initial Parameters
    L = 5000; % of initial steps in my historical timeseries

    S0 = 1; % initial stock price
    %rng(999); % for reproducibility
    rng('shuffle');
    a = 0.04; % fixed time trend coefficient

    % drift 
    driftB = -0.005;
    driftAR = 0.01;
    drift2B = 0.00009;
    drift2AR = 0.0001;

    % time
    T = 1; % stands for one year
    tradingDaysNo = 252;
    DaysNo = 365;
    dt = T/tradingDaysNo;

    % garch 
    desiredAnnualisedLongTermSigma = 0.30;  % this number won't be achieved because of the GARCH dynamics itself !!!
    LongTermVariance = (desiredAnnualisedLongTermSigma^2)*dt;  % get single unit of time long term variance
    V0 = LongTermVariance;
    alpha_e = 0.78;
    beta_e = 0.21;
    gamma_e = (1 - alpha_e - beta_e);
    omega_e = gamma_e * LongTermVariance;

    % generates date and raw random data
    sample_date = datetime(busdays(today()-L,today()),'ConvertFrom','datenum');
    sample_date.Format = 'defaultdate';
    L = numel(sample_date);
    sample_random = randn(L,1);


    for t = 1:L

        date_distance = datenum(sample_date(t))-datenum(sample_date(1));
        yf = date_distance / DaysNo;

        % 1) time trend with seasonal component
        if month(sample_date(t))<7 
            seas_sign =  1;
        else
            seas_sign = -1;
        end

        TT(t,1) = a*yf/2 + a*yf/4 * sin(4 * pi * yf) + a*yf/4 * cos(2 * pi * yf)*seas_sign;

        % DRIFTS FOR THE EQUITY LIKE TERM
        % 2) drifts from:
        if t == 1
            % drift1
            mu_drift(t,1) = driftB * sample_random(t,1); 
            % drift squared
            mu_drift2(t,1) = drift2B * sample_random(t,1)^2; 
        else
            mu_drift(t,1) = driftB*sample_random(t,1)  +  driftAR*sample_random(t-1,1);
            mu_drift2(t,1) = drift2B*sample_random(t,1)^2  +  drift2AR*sample_random(t-1,1)^2;
        end

        dP(t,1) = mu_drift(t,1) + mu_drift2(t,1);

        % 3) global diffusion term
        % sigma(k) = sigma0 + alpha*sigma(k-1) + (beta*np.random.normal(0,1))*np.sqrt(dt)
        % deps(k)

        z = randn(1);
        if t == 1
            variance(t,1) = V0; 
            sigma_e(t,1) = 0;
            e(t) = sigma_e(t) * z;
        else
            variance(t,1) = omega_e + alpha_e*variance(t-1) + beta_e*e(t-1)^2;
            sigma_e(t,1) = sqrt(variance(t));
            e(t,1) = sigma_e(t) * z;
        end

        % equity  pricing
        if t == 1
            equityPrice(t,1) = S0 * exp(dP(t));
        else
            equityPrice(t,1) = equityPrice(t - 1,1) * exp(dP(t) + sigma_e(t)*randn(1));
        end
    end

    PriceSample = table(sample_date, equityPrice + TT);
    PriceSample.Properties.VariableNames(2)={'prices'};
    
    %%%% PLOT: to be deleted for final version 
    
    figure();
    hold
    %plot(dP);
    plot(exp(cumsum(dP)));
    plot(TT);
    
    %%%%

end