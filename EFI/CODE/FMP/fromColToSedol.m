function [sedol,isin] = fromColToSedol (chiave,sedolMap, isinMap)
 sedolcell=sedolMap(chiave{1});
 isincell=isinMap(chiave{1});
 arraysedol=sedolcell{1};
 arrayisin=isincell{1};
 sedol=arraysedol(chiave{2});
 isin=arrayisin(chiave{2});
end