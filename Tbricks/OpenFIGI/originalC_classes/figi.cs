using RestSharp;
using System.IO;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Text.RegularExpressions;
using Newtonsoft.Json;

namespace FigiApiCsharpExample
{
    public class Figi
    {
        public string GetFigi(List<string> ISIN) // to test from Program.cs (as a console app, not library components)
        // public void GetFigi(string ISIN, out string result)
        {
            // input is a vector of ISIN codes. For each one of them I will get aJSON formatted set of data,
            // that are decoded through matlab GetFigi.m code
            var client = new RestClient("https://api.openfigi.com/v1/mapping");
            // client.Proxy = new WebProxy("10.244.0.61:8080"); // 9090
            client.Proxy = new WebProxy("http://inet1.gtm.corp.sanpaoloimi.com:9090"); // 9090

            var request = new RestRequest(Method.POST);
            request.RequestFormat = DataFormat.Json;
            request.AddHeader("X-OPENFIGI-APIKEY", "384c61d2-2263-4cac-b8dc-6035b39fd143");
            request.AddHeader("Content-Type", "text/json");

           
            

            var list = new List<OpenFIGIRequest>();
            /*
             // TO BE USED FOR TESTING FROM Program.cs (with the subsequent for loop and the 'list' def above commented)
            var list = new List<OpenFIGIRequest>()
            {
                // new OpenFIGIRequest("ID_ISIN", ISIN),
                new OpenFIGIRequest("TICKER", "MSFT").WithExchangeCode("US").WithMarketSectorDescription("Equity"),
                new OpenFIGIRequest("ID_BB_GLOBAL", "BBG000BLNNH6")
               
            };
            */

            foreach (string element in ISIN)
            {
                list.Add(new OpenFIGIRequest("ID_ISIN", element));
            };

            //list.Add(new OpenFIGIRequest("ID_ISIN", ISIN));
            request.RequestFormat = DataFormat.Json;
            request.JsonSerializer = new NewtonsoftJsonSerializer();
            request.AddJsonBody(list);

            var response = client.Post<List<OpenFIGIArrayResponse>>(request);
            // result = response.Content;

            // check
            // string test = JsonConvert.SerializeObject(ISIN.ToArray());
            // System.IO.File.WriteAllText(@"D:\test.txt", test);

            // uncomment when debugging from Program.cs as a console application
            string result;

            result = response.Content;

            string json = JsonConvert.SerializeObject(result, Formatting.Indented);

            //write string to file
            // System.IO.File.WriteAllText(@"D:\path.txt", json);
            string currentFolder = Directory.GetCurrentDirectory();
            string OutputFileName = currentFolder + @"\OutputData\json.txt";
            System.IO.File.WriteAllText(OutputFileName, json);

            // uncomment when debugging from Program.cs as a console application
            return result;


            /*
            foreach(var dataInstrument in response.Data)
                if (dataInstrument.Data != null && dataInstrument.Data.Any())
                    foreach(var instrument in dataInstrument.Data)
                        Console.WriteLine(instrument.SecurityDescription); */
        }
    }
}
