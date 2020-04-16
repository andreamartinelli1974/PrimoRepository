xdata=[1 2 3 4 5 6 7 8 9 10 11 12 13 14];
ydata=[9789 9862 9877 9950 10087 10222 10349 10498 10553 10592 10646 10793 10914 11069];
x0=[1 ; 0.1];
fun=@(x,xdata)x(1)*9749*exp(x(2)*xdata)./(x(1)+9749*(exp(x(2)*xdata)-1))
[x,resnorm] = lsqcurvefit(fun,x0,xdata,ydata);