function [cellarray]=cleanRF(cellarray)
%cellarray is a row vector
emptyRf=find(strcmp(cellarray,''));
cellarray(emptyRf)=[];
end