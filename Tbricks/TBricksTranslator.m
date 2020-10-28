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
        
        mainTable = [];
        InvestmentUniverse;
        
        EquitiesLabels = {'Common/Ordinary shares','ETF','Units'};
        FuturesLabels = {'Financial Futures'};
        OptionsLabels = {'Call','Put'};
        
        mkt_map
        mkt_map_key = {'CAD','CHF','DKK','GBP','HKD','JPY','NOK','SEK','USD'};
        mkt_map_val = {'CN','SW','DC','LN','HK','JP','NOK','SEK','US'};
        
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
           % get data from bbg
           isin_crncy = [EquitiesTable.ISIN,EquitiesTable.CURRENCY];
           isin_crncy = unique(isin_crncy,'row');
           
           %remove missing data
           isin_crncy(strcmp("",isin_crncy(:,1)),:) = [];
           isin_crncy(strcmp("000000000000",isin_crncy(:,1)),:) = [];
           
           output = readFigi(TT,isin_crncy);
           
           
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
           
           % create empty string array to collect bbg tickers
           bbg_tkr_list = strings(numel(output_figi),1);
           
           for i = 1:numel(output_figi)
                ccy = my_isin_list(i,2);
                switch ccy
                    case 'EUR'
                        figi_ticker = output_figi{1, i}.data{1, 1}.ticker;
                        figi_mkt = output_figi{1, i}.data{1, 1}.exchCode;
                        bbg_tkr_list(i) = strcat(figi_ticker," ",figi_mkt," Equity");
                    otherwise
                        %do nothing at the moment
                end
           end
           
       end % end readFigi
   end
end