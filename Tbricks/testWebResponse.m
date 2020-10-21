% uri = matlab.net.URI('http://httpbin.org/post');
% res = webwrite(uri,'field1','hello','field2','world');
% res.form

openfigiURL = 'https://api.openfigi.com/v1/mapping';
options = weboptions('HeaderFields',{'Content-Type','text/json';...
                     'X-OPENFIGI-APIKEY','b72bef06-a772-44de-9bec-056836c04e85'},...
                     'ContentType','json','ArrayFormat','json');
idType_name = 'idType';
idType_value = 'ID_ISIN';
idValue_name = 'idValue';
idValue_value = 'GB00B03MLX29';
data = {'"idType":"ID_ISIN","idValue":"GB00B03MLX29"'};
response = webwrite(openfigiURL,data,options);

% uri = matlab.net.URI('https://api.openfigi.com/v1/mapping');
% 
% myBody = matlab.net.http.MessageBody;
% myBody.Data={'"idType":"ID_ISIN","idValue":"GB00B03MLX29"'};
% myHeader = matlab.net.http.HeaderField('Content-Type','text/json',...
%            'X-OPENFIGI-APIKEY','b72bef06-a772-44de-9bec-056836c04e85');
% myMethod = 'POST';
% myProxy = matlab.net.URI('http://10.244.0.61:8080');
% myOptions = matlab.net.http.HTTPOptions;
% myOptions.ProxyURI = myProxy;
% 
% myCred = matlab.net.http.Credentials('Scheme','Basic','Username','u093799','Password','Ulisse01');
% myOptions.Credentials = myCred;
%       
% request = matlab.net.http.RequestMessage(myMethod,myHeader,myBody);
% response = sendRequest(uri,request,myOptions);

