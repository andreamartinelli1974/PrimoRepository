

function [cellarraySettoriale,cardMatrix,costituents]=sectorNeutralPortfolio_weight(MatrixCleaned, vectorKeys,sortFactor,Npercentili,sedolchk)
%INPUT:
%MatrixCleaned:Matrix that has as column [factor,simplereturn,compreturn,
%              settorNumber] cleaned by missing values
%vectorKeys: vector whom elements are sector numeber ICB of the 10 sectors
%            considered

%OUTPUT: CellArray that has as elements FMP sector neutral. i.e. the first
%element is the portfolio composed by the top companies of each sector.


sectorVector=MatrixCleaned(:,4);

for nsettori=1:length(vectorKeys)
    sectorcode=vectorKeys{nsettori};
    index_sector=find(sectorVector==sectorcode);
    factormatrix_settore=MatrixCleaned(index_sector,:); % submatrice formata da fattore e rispettivi ritorni
    sedolSector=sedolchk(index_sector);
    [factorsorted, index_sort]=sort(factormatrix_settore(:,1),sortFactor);
    simplereturn=factormatrix_settore(:,3);
    simplereturn_sorted=simplereturn(index_sort);
    compreturn=factormatrix_settore(:,2);
    compreturn_sorted=compreturn(index_sort);
    sedolSectorSorted = sedolSector(index_sort);
    [startvector,endvector,cardIndx]=dividePercentile(factorsorted,Npercentili);
    
    %matrix that has as rows sectors and as columns nperc: the element Mij
    %is the number of companies in the j-ptf for the i-ism sector
    if nsettori==1
        for k=1:length(cardIndx)
            cardVerctor=ones(cardIndx(k),1);
            cardMatrix{k}=cardVerctor*((1/cardIndx(k))*(length(index_sector)/length(sectorVector)));
        end
    else
        for k=1:length(cardIndx)
            cardVerctor=ones(cardIndx(k),1); %mi serve per fissare la lunghezza
            vectorSector=cardVerctor*((1/cardIndx(k))*(length(index_sector)/length(sectorVector)));
            cardMatrix{k}=[cardMatrix{k}; vectorSector];
        end
    end
    
    for perc=1:Npercentili
        if nsettori==1 % se sono al primo settore creo le matrici
            cellarraySettoriale{perc}=[factorsorted(startvector(perc):endvector(perc)),simplereturn_sorted(startvector(perc):endvector(perc)),compreturn_sorted(startvector(perc):endvector(perc))];
            costituents{perc}=sedolSectorSorted(startvector(perc):endvector(perc));
            
        else   %aggiungo quartile degli altri settori a quelli precedenti
            
            oldMatrix=cellarraySettoriale{perc};
            toaddMatrix=[factorsorted(startvector(perc):endvector(perc)),simplereturn_sorted(startvector(perc):endvector(perc)),compreturn_sorted(startvector(perc):endvector(perc))];
            cellarraySettoriale{perc}=[oldMatrix;toaddMatrix];
            costituents{perc}=[costituents{perc};sedolSectorSorted(startvector(perc):endvector(perc))];
        end
        
    end
    
    
    clear factormatrix_settore
    clear factorsorted
    clear simplereturn simplereturn_sorted
    clear compreturn compreturn_sorted
end
end