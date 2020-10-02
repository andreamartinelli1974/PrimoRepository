function [lastSlice,sedolCell]=createLastSlice(filename,riskFactors)
    [timeslice,sedolCell]=read_factors_Map_Sector(filename);
    rfdata=datastore(filename,'Range','P5:IC5');
    rf=rfdata.VariableNames;
    for i=1:length(riskFactors)-2
        col=find(strcmp(rf,riskFactors(i)));
        if isnan(col)==1
           x='error';
        end
        lastSliceFactor(:,i)= timeslice(:,col);
    end
    ref_data=ones(size(timeslice,1),1)*20191129;
    lastSlice=[ref_data,timeslice(:,1:2),lastSliceFactor,timeslice(:,end-3:end-1)];
end