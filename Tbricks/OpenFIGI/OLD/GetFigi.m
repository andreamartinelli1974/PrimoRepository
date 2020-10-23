
% look at C:\Users\u370176\Documents\GitHub\C_Projects\MatlabNet_Interactions.doc
% section "Call .NET Methods With out Keyword"

DLLpath = 'C:\Users\u370176\Documents\GitHub\C_Projects\OpenFIGI_api-examples\csharp\FigiApiCsharpExample\bin\Debug\';
DLLname = 'FigiApiCsharpExample.dll';
asm = NET.addAssembly(fullfile(DLLpath,DLLname)); % add the assembly to the .NET available libraries

cls = FigiApiCsharpExample.Figi % create an instance of the class (use the syntax: namespace name.class name)
% ISIN = 'US3453708600'; % INPUT

% read input ISINs
[i1,i2] = xlsread('isinList.xls');

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

xlswrite('testOutput',outFigi);

% OLD: to generater a key-value pairs map between the name of each output field
% and its content (e.g. 'figi' and 'BBG883899992' )
% mappings.(ISIN) = containers.Map;
    % process single tokens to identify key/value pairs to feed a dictionary
%     for k=1:nTokens
%         key = extractBefore(tokens{k},":");
%         value = extractAfter(tokens{k},":");
%         mappings.(ISIN)(key) = value;
%     end