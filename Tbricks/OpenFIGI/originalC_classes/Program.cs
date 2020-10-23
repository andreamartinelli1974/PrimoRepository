using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Collections;
using System.Data;
using System.Windows; // this is needed to be able to add WPF to the console application
namespace FigiApiCsharpExample
{
    class Program
    {
        static void Main(string[] args)
        {
            // written to be used as a library class, invoked from within Matlab code 
            // GetFigi.m
            // for testing purposes only use the code below, after changing the figi class header to the 
            // commented one and setting the Output type to Console Application into Project->Properties->Apps 
            // also, a few more changes are needed within figi.cs

            // test
            // uncomment when debugging from Program.cs as a console application
            /*
            string result;
            string[] testString = { "US3453708600", "FR0000120172", "DE0007042301", "IT0005244592" };
            result = Figi.GetFigi(testString);*/

            Console.WriteLine("disp"); 

            string currentFolder = Directory.GetCurrentDirectory();
            string InputFileName = currentFolder + @"\InputData\isinList.csv";

            // INPUT INVESTMENT UNIVERSE
            // TODO: later create a general abstract class for inputs that ca be used with several sources (.csv and .cls to start with)

            // EXCEL
            // InputFolder from Excel will be done later since on the home PC I don not have the Interoperability Assemply
            // InputFromExcel IU_data = new InputFromExcel(InputFolder, "Investment_Universe.xls", "DevTests");

            // CSV
            bool withHeaders = false;
            CsvReader IU = new CsvReader(InputFileName, withHeaders);
            var isinCodes = new List<string>();

            int cnt = 0;
            while (!IU.EOF)
            {
                string[] inputRow = IU.Read();
                
                isinCodes.Add(inputRow[0]);
                Console.WriteLine("ISIN: " + isinCodes[cnt]);
                cnt = cnt + 1;
            }

            Figi F = new Figi();
            string output = F.GetFigi(isinCodes);
            Console.WriteLine("Execution completed");
        }

    }
}