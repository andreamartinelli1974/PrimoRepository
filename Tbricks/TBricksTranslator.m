classdef TBricksTranslator < handle
    properties (SetAccess=private)
        isinInputFolder = [cd,'\InputData\'];
        jsonInputFolder = [cd,'\OutputData\'];
    end
    
    properties
        EquityPtfNames
        DataFromBBG
        InputTable
        
        Equities;
        Futures;
        Options;
        NotFound;
        
        mainTable = [];
        InvestmentUniverse;
        
        EquitiesLabels = {'Common/Ordinary shares','ETF','Units'};
        FuturesLabels = {'Financial Futures'};
        OptionsLabels = {'Call','Put'};
        
        mkt_map
        mkt_map_key = {'CAD','CHF','DKK','GBP','HKD','JPY','NOK','SEK','USD'};
        mkt_map_val = {'CN','SW','DC','LN','HK','JP','NO','SS','US'};
        
        FIGI
   end
       
   methods
       function TT = TBricksTranslator(params)
           % get the params
           TT.EquityPtfNames = params.EquityPtfNames;
           TT.DataFromBBG = params.DataFromBBG;
           TT.InputTable = params.mainPtfTable;
           
           %setup the map
           TT.mkt_map = containers.Map(TT.mkt_map_key, TT.mkt_map_val);
           
           % filter the master table to have only the Equity Desk Portfolios
           ptfNumber = numel(TT.EquityPtfNames);
           
           for i =1:ptfNumber
               tempTable = TT.InputTable(strcmp(TT.InputTable.PORTFOLIOID_FE, TT.EquityPtfNames(i)),:);
               if i==1
                   TT.mainTable = tempTable;
               else
                   TT.mainTable = [TT.mainTable; tempTable];
               end
               clear tempTable;
           end
           
           TT.translateEquity;
           TT.translateFutures;
           TT.translateOptions;
           
       end % end constructor
       
       function translateEquity(TT)
           % filter by asset class: only Equity-like assets
           ptfNumber = numel(TT.EquitiesLabels);
           EquitiesTable = [];
           
           for i =1:ptfNumber
               tempTable = TT.mainTable(strcmp(TT.mainTable.MTYPE, TT.EquitiesLabels(i)),:);
               if i==1
                   EquitiesTable = tempTable;
               else
                   EquitiesTable = [EquitiesTable; tempTable];
               end
               clear tempTable;
           end
           
           isin_crncy_All = [EquitiesTable.ISIN,EquitiesTable.CURRENCY];
           [isin_crncy_unique,~,idx] = unique(isin_crncy_All,'row');
           
           %remove missing data
           no_isin = strcmp("",isin_crncy_unique(:,1));
           zero_isin = strcmp("000000000000",isin_crncy_unique(:,1));
           exceptions = no_isin + zero_isin;
           isin_crncy = isin_crncy_unique(~exceptions,:);
           
           % get data from openFIGI using ISIN
           [output,isin_ccy_error] = readFigi(TT,isin_crncy);
           
           % insert the ticker in the table
           isin_crncy_unique(~exceptions,3) = output(:,3);
           TT.Equities = EquitiesTable;
           TT.Equities.TICKER = isin_crncy_unique(idx,3);
           
           TT.NotFound = [isin_crncy_unique(logical(exceptions),1:2);isin_ccy_error];
           
           % TO DO: manage exceptions
           
           EquNotFound = TT.Equities(ismissing(TT.Equities.TICKER),:);
           writetable(EquNotFound,'EquitiesNotFound.xlsx');
           
       end % end translateEquity
       
       function translateFutures(TT)
           % filter by asset class: only Equity-like assets
           ptfNumber = numel(TT.FuturesLabels);
           FuturesTable = [];
           
           for i =1:ptfNumber
               tempTable = TT.mainTable(strcmp(TT.mainTable.MTYPE, TT.FuturesLabels(i)),:);
               if i==1
                   FuturesTable = tempTable;
               else
                   FuturesTable = [FuturesTable; tempTable];
               end
               clear tempTable;
           end
           
           isin_crncy_All = [FuturesTable.ISIN,FuturesTable.CURRENCY];
           [isin_crncy_unique,~,idx] = unique(isin_crncy_All,'row');
           
           %remove missing data
           no_isin = strcmp("",isin_crncy_unique(:,1));
           zero_isin = strcmp("000000000000",isin_crncy_unique(:,1));
           exceptions = no_isin + zero_isin;
           isin_crncy = isin_crncy_unique(~exceptions,:);
           
           % get data from openFIGI using ISIN
           [output,isin_ccy_error] = readFigi(TT,isin_crncy);
           
           % insert the ticker in the table
           isin_crncy_unique(~exceptions,3) = output(:,3);
           TT.Futures = FuturesTable;
           TT.Futures.TICKER = isin_crncy_unique(idx,3);
           
           FutNotFound = TT.Futures(ismissing(TT.Futures.TICKER),:);
           writetable(FutNotFound,'FuturesNotFound.xlsx');
           
       end %end translateFuture
       
       function translateOptions(TT)
           % filter by asset class: only Equity-like assets
           ptfNumber = numel(TT.OptionsLabels);
           OptionsTable = [];
           
           for i =1:ptfNumber
               tempTable = TT.mainTable(strcmp(TT.mainTable.MTYPE, TT.OptionsLabels(i)),:);
               if i==1
                   OptionsTable = tempTable;
               else
                   OptionsTable = [OptionsTable; tempTable];
               end
               clear tempTable;
           end
           
           isin_crncy_All = [OptionsTable.ISIN,OptionsTable.CURRENCY];
           [isin_crncy_unique,~,idx] = unique(isin_crncy_All,'row');
           
           %remove missing data
           no_isin = strcmp("",isin_crncy_unique(:,1));
           zero_isin = strcmp("000000000000",isin_crncy_unique(:,1));
           exceptions = no_isin + zero_isin;
           isin_crncy = isin_crncy_unique(~exceptions,:);
           
           % get data from openFIGI using ISIN
           [output,isin_ccy_error] = readFigi(TT,isin_crncy);
           
           % insert the ticker in the table
           isin_crncy_unique(~exceptions,3) = output(:,3);
           TT.Options = OptionsTable;
           TT.Options.TICKER = isin_crncy_unique(idx,3);
           
           OptNotFound = TT.Options(ismissing(TT.Options.TICKER),:);
           writetable(OptNotFound,'OptionsNotFound.xlsx');
           
       end % end translateOptions
       
       function output = getFigi(TT)
           EXEpath = [cd,'\OpenFIGI\EXE\'];
           EXEname = 'FigiApiCsharpExample.exe';
           fullName = fullfile(EXEpath,EXEname);

           system(fullName);
           
           json2beparsed = jsondecode(fileread([TT.jsonInputFolder 'json.txt']));
           output = parse_json(json2beparsed);
       end
       
       function [output,isin_ccy_error] = readFigi(TT,isin_currency_list)
           % output is a cell array with 3 columns:
           % 1) isin  2) currency  3) bbg ticker
           isin_list = isin_currency_list(:,1);
           if numel(isin_list) > 100
               chunk_nr = ceil(numel(isin_list)/100);
           else
               chunk_nr = 1;
           end
           
           output_figi = [];
           
           for i = 1:chunk_nr
               if i == chunk_nr
                   isinTosave = isin_list(1+100*(i-1):end);
               else
                   isinTosave = isin_list(1+100*(i-1):100*i);
               end
               myList = table(isinTosave(2:end),'VariableNames',isinTosave(1));
               writetable(myList,[TT.isinInputFolder,'isinList.csv']);
               
               outFigi = TT.getFigi;
               
               output_figi = [output_figi, outFigi];
               
               clear myList;
           end
           
           TT.FIGI = output_figi;
           
           error_list = zeros(numel(output_figi),1);
           for i = 1:numel(output_figi)
               if isfield(output_figi{1,i},'error')
                   error_list(i,1)=1;
               end
           end
           
           isin_ccy_error = isin_currency_list(logical(error_list),:);
           my_isin_list = isin_currency_list(logical(~error_list),:);
           output_figi = output_figi(logical(~error_list));
           
           bbg_tkr_list = TT.getTickers(my_isin_list,output_figi);
           output = isin_currency_list;
           output(~error_list,3) = bbg_tkr_list;
              
       end % end readFigi
       
       function bbg_tkr_list = getTickers(TT,my_isin_list,output_figi)
           
           
           % create empty string array to collect bbg tickers
           bbg_tkr_list = strings(numel(output_figi),1);
           
           for i = 1:numel(output_figi)
               ccy = my_isin_list(i,2);
               switch ccy
                   case 'EUR'
                       figi_ticker = output_figi{1, i}.data{1, 1}.ticker;
                       figi_mkt = output_figi{1, i}.data{1, 1}.exchCode;
                       bbg_tkr_list(i) = strcat(figi_ticker," ",figi_mkt," Equity");
                       
                   case 'CAD'
                       j = 1;
                       figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       while ~strcmp(TT.mkt_map('CAD'),figi_mkt)
                           j=j+1;
                           figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       end
                       figi_ticker = output_figi{1, i}.data{1, j}.ticker;
                       bbg_tkr_list(i) = strcat(figi_ticker," ",figi_mkt," Equity");
                       
                   case 'CHF'
                       j = 1;
                       figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       while ~strcmp(TT.mkt_map('CHF'),figi_mkt)
                           j=j+1;
                           figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       end
                       figi_ticker = output_figi{1, i}.data{1, j}.ticker;
                       bbg_tkr_list(i) = strcat(figi_ticker," ",figi_mkt," Equity");
                       
                   case 'DKK'
                       j = 1;
                       figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       while ~strcmp(TT.mkt_map('DKK'),figi_mkt)
                           j=j+1;
                           figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       end
                       figi_ticker = output_figi{1, i}.data{1, j}.ticker;
                       bbg_tkr_list(i) = strcat(figi_ticker," ",figi_mkt," Equity");
                       
                   case 'GBP'
                       j = 1;
                       figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       while ~strcmp(TT.mkt_map('GBP'),figi_mkt)
                           j=j+1;
                           figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       end
                       figi_ticker = output_figi{1, i}.data{1, j}.ticker;
                       bbg_tkr_list(i) = strcat(figi_ticker," ",figi_mkt," Equity");
                       
                   case 'HKD'
                       j = 1;
                       figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       while ~strcmp(TT.mkt_map('HKD'),figi_mkt)
                           j=j+1;
                           figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       end
                       figi_ticker = output_figi{1, i}.data{1, j}.ticker;
                       bbg_tkr_list(i) = strcat(figi_ticker," ",figi_mkt," Equity");
                       
                   case 'JPY'
                       j = 1;
                       figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       while ~strcmp(TT.mkt_map('JPY'),figi_mkt)
                           j=j+1;
                           figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       end
                       figi_ticker = output_figi{1, i}.data{1, j}.ticker;
                       bbg_tkr_list(i) = strcat(figi_ticker," ",figi_mkt," Equity");
                       
                   case 'NOK'
                       j = 1;
                       figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       while ~strcmp(TT.mkt_map('NOK'),figi_mkt)
                           j=j+1;
                           figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       end
                       figi_ticker = output_figi{1, i}.data{1, j}.ticker;
                       bbg_tkr_list(i) = strcat(figi_ticker," ",figi_mkt," Equity");
                       
                   case 'SEK'
                       j = 1;
                       figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       while ~strcmp(TT.mkt_map('SEK'),figi_mkt)
                           j=j+1;
                           figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       end
                       figi_ticker = output_figi{1, i}.data{1, j}.ticker;
                       bbg_tkr_list(i) = strcat(figi_ticker," ",figi_mkt," Equity");
                       
                   case 'USD'
                       j = 1;
                       figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                       while ~strcmp(TT.mkt_map('USD'),figi_mkt)
                           j=j+1;
                           figi_mkt = output_figi{1, i}.data{1, j}.exchCode;
                           if j == numel(output_figi{1, i}.data)
                               break;
                           end
                       end
                       figi_ticker = output_figi{1, i}.data{1, j}.ticker;
                       bbg_tkr_list(i) = strcat(figi_ticker," ",figi_mkt," Equity");
                       
                   otherwise
                       error(strcat(ccy, " not found: must be mapped in TBricksTranslator"));
                       %do nothing at the moment
               end
           end
       end % getTickers
   end
end