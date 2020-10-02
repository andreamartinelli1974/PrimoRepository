clear all
close 
clc

userId = getenv('USERNAME');
addpath(['C:\Users\',userId,'\Desktop\EFI\CODE\input']);
addpath(['C:\Users\',userId,'\Desktop\EFI\CODE\input\anagrafiche']);
outputpath='C:\Users\u369343\Desktop\EFI\CODE\output\newSedols\';


[newSedol]=read_factors_Map_Sector('forwardPTF.xlsx');
if isempty(newSedol)==0
   disp('** NUOVI SEDOL DA INSERIRE IN ANAGRAFICA');
   writecell(newSedol,strcat(outputpath,'newsedol.xlsx'));
else
    disp('** NON CI SONO NUOVI SEDOL DA INSERIRE IN ANAGRAFICA');
end