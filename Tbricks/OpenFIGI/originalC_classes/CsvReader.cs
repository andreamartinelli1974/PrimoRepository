using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO; // StreamWriter an StreamReader

namespace FigiApiCsharpExample
{
    public class CsvReader
    {
        #region private fields
        const char CsvSeparator = ',';
        private readonly StreamReader reader;
        #endregion
        public string[] headers { get; set; }

        public CsvReader(string filePath, bool withHeaders)
        {
            var fs = new FileStream(filePath, FileMode.Open, FileAccess.Read);
            reader = new StreamReader(fs);

            {
                if (reader.EndOfStream) throw new Exception("Empty file: " + filePath);

                if (withHeaders)
                {
                    string crudeData = reader.ReadLine();
                    headers = crudeData.Split(CsvSeparator);
                    //var splitData = crudeData.Split(CsvSeparator);
                    //headers = new Dictionary<string, int>();
                    /*for (int i = 0; i < splitData.Length; i++)
                   {
                      if (headers.ContainsKey(splitData[i]))
                           headers.Add(splitData[i] + ".0", i);
                       else
                           headers.Add(splitData[i], i); 
                   }*/
                }
            }
        } // constructor

        public bool EOF
        {
            get
            {
                return reader.EndOfStream;
            }
        }
        public string[] Read()
        {
            string crudeData = reader.ReadLine();
            var splitData = crudeData.Split(CsvSeparator);
            return splitData;
        }
        public void Close()
        {
            reader.Close();
        }

    }
}
