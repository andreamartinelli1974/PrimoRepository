clc; close all; clear all;

userID = getenv('USERNAME');
pwd = passwordUI;

assemblyPath = [cd,'\DLLs\']; % subfolder where DLLs are
assemblyName_1 = 'AutoEmails.dll';
fullName_1 = fullfile(assemblyPath,assemblyName_1);
assembly_1 = NET.addAssembly(fullName_1);

% testemail = "gianpiero.preziosi@gmail.com";
emails = AutoEmails.MailSettingsSetup(); % create an instance of the class (namespace name . class name)
createSenderObj(emails,string(userID),string(pwd)); % invoke method 'createSenderObj'
callSendMethod(emails,"test email for Pair Trading Strategy ","**** test test test ****"); % invoke method 'callSendMethod'

M = msgbox('If a test email is not received within a few seconds it means that there is a problem (e.g. incorrect password) that will prevent the delivery of autoamtically generated emails');
waitfor(M);
