%% TO BE REWRITTEN TO INCORPORATE CHANGES TO THE DLL (see GetFigi code),now working 
% in a vectorized way and getting a full table of info for each ISIN code

% when deploying the xla copy the updated C# DLLs files into C:\Windows\System32\DLLs

function outFigi = isin2figi(isin)
% Excel version of the GetFigi code, designed to be compiled and deployed
% as an Excel addin


DLLpath = [cd,'\','DLLs\']; % C# DLLs must be in a subfolder of the working folder
DLLname = 'FigiApiCsharpExample.dll';
asm = NET.addAssembly(fullfile(DLLpath,DLLname)); % add the assembly to the .NET available libraries

cls = FigiApiCsharpExample.Figi % create an instance of the class (use the syntax: namespace name.class name)
% ISIN = 'US3453708600'; % INPUT

% read input ISINs
% [i1,i2] = xlsread('isinList.xls');
i2 = isin; % input from the user

numISIN  = numel(i2);

% loop over al ISINs and get the output from OpenFIGI  for each one of them
clear outFigi;
for k=1:numISIN
    ISIN = i2{k}; % INPUT
    
    result = GetFigi(cls,ISIN); % use the 'GetFigi' method (of the C# class instantiated above)
    
    % result is an obj of .NET class System.String: need to be converted to
    % Matlab 'char' to be used. The result is then converted in Matlab string to
    % be processed further
    output = string(char(result)); % OUTPUT (unfiltered)
    
    % 1st: preprocessing: removing superfluous characters
    filtered_1 = erase(output,{'"data":','"','{','}','[',']'})
    % 2nd: parse tokens based on commas
    expression = ','
    [tokens]=regexp(filtered_1,expression,'split');
    
    nTokens = numel(tokens); % # of identified tokens
       
    done = false(1);
    cnt = 0;
    while ~done
        cnt = cnt + 1;
        if strcmp(extractBefore(tokens{cnt},":"),'figi')
           done = true(1);
           outFigi{k,1} = ISIN;
           outFigi{k,2} = extractAfter(tokens{cnt},":");
        end
    end
end

end

