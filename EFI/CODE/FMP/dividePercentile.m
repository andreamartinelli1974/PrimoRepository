
function [startVector,endVector,countindx,factorNan]=dividePercentile(factor_sorted,NtotalPercentili)

%%
%INPUT:
%factor_cleaned: vettore ordinato che rappresenta un fattore di rischio fissato un tempo t
%NtotalPercentili: numero di percentili in cui si vuole dividere il fattore
%                  di rischio

%OUTPUT:
%startVector: vettore che contiene le posizioni dell'elemento iniziale di
%             ogni percentile
%endVector: vettore che contiene le posizioni dell'elemento finale di
%           ogni percentile
%countindx: cardinalità di ogni percentile 

%FUNCTION:
% Come primo passo la funzione associa ad ogni valore del fattore un
% posione di rank in modo da poter individuare possibili valori uguali che
% andranno inseriti, per coerenza, in uno stesso frattile.
% Successivamente crea la suddivisione dei frattili in modo da avere
% frattili più numerosi al centro (così che i portafogli Long e Short abbiano
%sempre un lunghezza simile)


rank=zeros(1,length(factor_sorted));
rank(1)=1;
factorNan=false;
for i=2:length(factor_sorted)
    if(factor_sorted(i-1)==factor_sorted(i))
        rank(i)=rank(i-1);
    else
        rank(i)=rank(i-1)+1;
    end
end

NtitoliDaDividere = rank(end);
if NtitoliDaDividere<NtotalPercentili
   factorNan=true;
   startVector=NaN;
   endVector=NaN;
   countindx=NaN;
   return
end

countindx =zeros(1,NtotalPercentili);
cardport=floor(NtitoliDaDividere/NtotalPercentili);
count=ones(1,NtotalPercentili)*cardport;
rest=mod(NtitoliDaDividere,NtotalPercentili);

%calcolato i rest li divido nei percentili mediani
if rest~=0
    percentileMediano=ceil(NtotalPercentili/2); 
    count(percentileMediano)=count(percentileMediano)+1;
    valoricentrali=1; %numero di valori posizionati nel quantile centrale
    if rest>NtotalPercentili-2 %se ne ho troppi ne metto di più al centro
       count(percentileMediano)=count(percentileMediano)+1;
        valoricentrali=2;
    end
     stepdisp=1;
     steppari=1;
    for i=1:rest-valoricentrali 
        if mod(i,2)~=0
           
           count(percentileMediano+stepdisp)=count(percentileMediano+stepdisp)+1;
           stepdisp=stepdisp+1;
        else 
           count(percentileMediano-steppari)=count(percentileMediano-steppari)+1;
           steppari=steppari+1;
        end
    end
end


for i=2:length(count)
    count(i)=count(i-1)+count(i);
end
startVector=zeros(1,NtotalPercentili);
endVector=zeros(1,NtotalPercentili);
startVector(1)=1;
j=1;
for i=1:length(rank)
    if rank(i)<=count(j)
        countindx(j)=countindx(j)+1;
    else
        endVector(j) = startVector(j)+countindx(j)-1;
        j=j+1;
        startVector(j)=startVector(j-1)+countindx(j-1);
        countindx(j)=1;        
    end
end
endVector(j) = startVector(j)+countindx(j)-1;
end


