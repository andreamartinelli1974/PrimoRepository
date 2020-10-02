function [distance,dtw_matrix] =  mydtw(s, t, window)
    n = numel(s);
    m = numel(t);
    w = max([window, abs(n-m)]);
    dtw_matrix = zeros(n+1, m+1);

    for i = 1:(n+1)
        for j = 1:(m+1)
            dtw_matrix(i, j) = inf;
        end
    end
    dtw_matrix(1, 1) = 0;

    for i =2:n+1
        for j = max([2, i-w]):min([m+1, i+w])
            dtw_matrix(i, j) = 0;
        end
    end

    for i = 2:n+1
        for j = max([2, i-w]):min([m+1, i+w])
            cost = abs(s(i-1) - t(j-1));
            % take last min from a square box
            last_min = min([dtw_matrix(i-1, j), dtw_matrix(i, j-1), dtw_matrix(i-1, j-1)]);
            dtw_matrix(i, j) = cost + last_min;
        end
    end
    distance = dtw_matrix(end,end);
end
        
        