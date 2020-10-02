function  [corrMatrixSector,corrReturnSector]=factorcorrSN(sandwichData,rolling,ref_data_legend,rollinglag)
%% INPUT 
%sandwichData
% ref_date_legend: vector with all the ref_date in sandwichData
% rolling: 1 if rolling windows is required, 0 otherwise
%% OUTPUT:
 % if Rolling Windows == true 
 %    corrMatrixSector is a map that given an each ICB returns 148
 %                     correlations Matrix
 % else 
 %    corrMatrixSector is a map that returns the correlazion Matrix for each ICB code
 
icbCode=sandwichData(:,end);
legendaIcb=unique(icbCode);
for i=1:length(legendaIcb) %sector layer
    codeSector=legendaIcb(i);
    companies_index=find(icbCode==codeSector); %select companies for each sector
    sectorMatrix=sandwichData(companies_index,1:end-1); %create a submatrix with all rf  but the icb code
    
    %create Maps
    if rolling==false
        
        [corrMatrix,corrReturn]=factorcorr(sectorMatrix(:,2:end)); %all but refdate
        if i==1
            corrMatrixSector=containers.Map(codeSector,corrMatrix);
            corrReturnSector=containers.Map(codeSector,corrReturn);
        else
            corrMatrixSector(codeSector)=corrMatrix;
            corrReturnSector(codeSector)=corrReturn;
        end
        
    else  %map that link at each code sector a corr matrix for each rolling window
        [corrMatrix,corrReturn]=factorcorrRoll(sectorMatrix,ref_data_legend,rollinglag);
        
        if i==1
            corrMatrixSector=containers.Map(codeSector,corrMatrix);
            corrReturnSector=containers.Map(codeSector,corrReturn);
        else
            corrMatrixSector(codeSector)=corrMatrix;
            corrReturnSector(codeSector)=corrReturn;
        end
    end
end