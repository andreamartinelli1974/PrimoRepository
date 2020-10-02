function [matrixMember]=storeMembers(members, ref_date_ptf,t,matrixMember)

if t==1
    matrixMember=table(date,members);
else
    dateTable=[matrixMember;date];
    membersTable=[]
    membersmatrixNew=[ref_date_members,members];
    matrixMember=[matrixMember;membersmatrixNew];
end
end