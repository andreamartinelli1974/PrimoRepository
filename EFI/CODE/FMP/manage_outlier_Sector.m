function [cubodatiClean,sedolchkMapClean]= manage_outlier_Sector(cubodati,Nscarichi,outlierCap,sedolchkMap)

%%
%INPUT:
%cubodati: mappa che ha come chiave le date e come valore la matrice dei
%          fattori di rischio
%datename:vettore delle date corrispondenti alle date di scarico dei dati
%Nscarichi:numero di scarichi
%outlierCap:booleano che restituisce true se se vuole usare la gestione
%           degli outlier; false altrimenti.

%OUTPUT:
%cubodatiClean: cubodati con valori cappati per outlier(se
%               outlierCap==true)e ripulito degli NaN sui ritorni


%FUNZIONE:
% questa funzione prende in input il cubo dei dati e lo pulice
% togliendo prima gli outlier dai fattori
% poi gli Nan nei ritorni se la company non è più esistente

%% gestisto NaN
matrices=cubodati.values;

mapkeys=cubodati.keys;
for i=1:Nscarichi
    factorMatrix=matrices{1,i}; 
    sedolchks=sedolchkMap(mapkeys{i});
    sedolchk=sedolchks{1};
    [righe,colonne]=size(factorMatrix);
    
    %elimino gli outlier andando a settare come lim sup o inf tutti quei
    %valori non compresi tra [q1-3(q3-q1),q3+3(q3-q1)]
    if outlierCap==true
        for c=3:colonne-1 %fisso fattore tolgo primi due perchè sono ritorni e l'ultima contiene ICB Sector code
            q=quantile(factorMatrix(:,c),[0.25,0.75]); %calcolo il primo e terzo quartile
            numeroOut=0;
            for j=1:righe
                if factorMatrix(j,c)> q(2)+3*(q(2)-q(1))
                    factorMatrix(j,c) = q(2)+3*(q(2)-q(1));%estremo superiore
                    numeroOut=numeroOut+1;
                elseif factorMatrix(j,c)< q(1)-3*(q(2)-q(1))
                    factorMatrix(j,c)= q(1)-3*(q(2)-q(1)); %estremo inferiore
                    numeroOut=numeroOut+1;
                end
            end
        end
    end
    
    % pulisco NaN sui ritorni eliminando le company scadute
    nan_pos = isnan(factorMatrix(:,1)); %cerco NaN sui ritorni 
    if length(nan_pos)>=1
        [nan_index] = find(nan_pos==1);
        factorMatrix(nan_index,:)=[];
        sedolchk(nan_index)=[];
    end
    
    
    %creo la nuova mappa dei dati con le matrici dei fattori aggiustate
    if i==1
        cubodatiClean=containers.Map(mapkeys{i},factorMatrix);
        sedolchkMapClean=containers.Map(mapkeys{i},{sedolchk});
    else
        cubodatiClean(mapkeys{i})= factorMatrix;
        sedolchkMapClean(mapkeys{i})={sedolchk};
    end
    
end

end
