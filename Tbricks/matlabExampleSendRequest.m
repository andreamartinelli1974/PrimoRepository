request = matlab.net.http.RequestMessage;
uri = matlab.net.URI('https://www.mathworks.com/products');
response = sendRequest(uri,request);