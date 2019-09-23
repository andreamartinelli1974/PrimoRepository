using System;
using System.Collections.Generic;
using System.Text;
using System.Net.Mail;

namespace AutoEmails
{
    public class MailSettingsSetup
    {
        // hard coded params (for now)
        const string smtpServer = "smtp-isp.gtm.corp.sanpaoloimi.com";
        const int port = 25;
        const bool sslEnabled = false;

        EmailSender senderObj;
        List<MailAddress> addressList;

        public MailSettingsSetup()
        {
            // this is the constructur used for production purposes where (for now) the address list to be
            // used is hard coded below
            Console.WriteLine("Sending email");

            // Mailing List  (hard coded here for now)
            MailAddress address_1 = new MailAddress("claudio.cocchis@bancaimi.com");
            MailAddress address_2 = new MailAddress("gianpiero.preziosi@bancaimi.com");
            MailAddress address_3 = new MailAddress("diego.ostinelli@bancaimi.com");
            MailAddress address_4 = new MailAddress("gianpiero.preziosi@gmail.com");
            MailAddress address_5 = new MailAddress("andrea.martinelli@bancaimi.com");
            MailAddress address_6 = new MailAddress("stefano.monti@bancaimi.com");
            MailAddress address_7 = new MailAddress("pierluigi.passerone@bancaimi.com");
            MailAddress address_8 = new MailAddress("domenico.melotto@bancaimi.com");
            MailAddress address_9 = new MailAddress("niccolo.bardoscia @bancaimi.com");


            addressList = new List<MailAddress>();

            addressList.Add(address_1);
            addressList.Add(address_2);
            addressList.Add(address_3);
            addressList.Add(address_4);
            addressList.Add(address_5);
            addressList.Add(address_6);
            addressList.Add(address_7);
            addressList.Add(address_8);
            addressList.Add(address_9);

        } // MailSettingsSetup constructor

        public MailSettingsSetup(string mailaddress)
        {
            // this second constructor receives an input that must be an email address: it is used
            // fro testing purposes and simply send an email to the address provided in 'mailaddress'
            Console.WriteLine("Sending TEST email");

            // Mailing List  (hard coded here for now)
            MailAddress address_1 = new MailAddress(mailaddress);
            

            addressList = new List<MailAddress>();

            addressList.Add(address_1);
           

        } // MailSettingsSetup constructor II (for testing purposes)

        public void createSenderObj(string userID, string password)
        {
            string userName = userID + "@sede.corp.sanpaoloimi.com";
            string fromMail = userID + "@bancaimi.com";
            senderObj = new EmailSender(smtpServer, port, sslEnabled, userName,
               password, fromMail, "autoTS_signals");
        }

        public void callSendMethod(string emailObject, string emailText)
        {
            senderObj.Send(addressList, emailObject, emailText);
        }

    } // MailSettingsSetup class 
} // namespace
