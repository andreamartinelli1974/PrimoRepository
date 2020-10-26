classdef TBricksTranslator < handle
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
   end
       
   methods
       function TT = TBricksTranslator(params)
           % get the params
           TT.EquityPtfNames = params.EquityPtfNames;
           TT.DataFromBBG = params.DataFromBBG;
           TT.InputTable = params.mainPtfTable;
           
           % filter the master table to have only the Euqity Desk Portfolios
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
           
       end
       
       function translateEquity(TT)
           % filter by asset class: only Equity-like assets
           ptfNumber = numel(TT.EquityPtfNames);
           EquitiesTable = [];
           
           for i =1:ptfNumber
               tempTable = TT.mainTable(strcmp(TT.mainTable.PORTFOLIOID_FE, TT.EquityPtfNames(i)),:);
               if i==1
                   EquitiesTable = tempTable;
               else
                   EquitiesTable = [EquitiesTable; tempTable];
               end
               clear tempTable;
           end
           
           % get data from bbg
           [isin_list, idx, ~] = unique(EquitiesTable.ISIN);
           isin_list = strcat('/ISIN/',isin_list);
           isin_list(:,2)= EquitiesTable.FIID(idx,:);

           N = size(isin_list,1);
           % get the fields: EQ_FUND_CODE TICKER
           uparams.fields = {'DX895','TICKER'};
           uparams.override_fields = [];
           uparams.history_start_date = today();
           uparams.history_end_date = today();
           uparams.DataFromBBG = TT.DataFromBBG;
           
           
           for k=1:N
               k,N
               uparams.ticker = isin_list{k,1};
               U = Utilities(uparams);
               U.GetBBG_StaticData;
               
               % EQ_FUND_CODE
               if isempty(U.Output.BBG_getdata.DX895{:})
                   isin_list{k,3} = 'N/A';
               else
                   isin_list{k,3} = strcat(U.Output.BBG_getdata.DX895{:},' Equity');
               end
               % TICKER
               if isempty(U.Output.BBG_getdata.TICKER{:})
                   isin_list{k,4} = 'N/A';
               else
                   isin_list{k,4} = strcat(U.Output.BBG_getdata.TICKER{:},' Equity');
               end
           end
           
           tkrTable = array2table(isin_list);
           tkrTable.Properties.VariableNames = {'ISIN','TB_ID','FUND_TKR','TKR'};
           
           % write the tickers at the end of the table
           tb_code = unique(EquitiesTable.UNDERLYINGID);
           tb_code = rmmissing(tb_code);
           und_tkr = table('Size',[size(EquitiesTable.ISIN,1),2],...
                           'VariableNames',{'FUND_TKR','TKR'},'VariableType',{'string','string'});
           
           for i = 1:numel(tb_code)
               % find the code in ISIN_EOD
               idx = strcmp(tb_code{i},tkrTable.TB_ID);
               isin = tkrTable(idx,3:4);
               aa = find(strcmp(tb_code{i},tkrTable.TB_ID));
               if ~isempty(aa)
                   und_tkr(aa,:) = isin;
               end
           end
           
           EquitiesTable = [EquitiesTable,und_isin];
       end
       
       function translateFutures(TT)
           % filter by asset class: only Equity-like assets
           ptfNumber = numel(TT.FuturesLabels);
           FuturesTable = [];
           
           for i =1:ptfNumber
               tempTable = TT.mainTable(strcmp(TT.mainTable.PORTFOLIOID, TT.FuturesLabels(i)),:);
               if i==1
                   FuturesTable = tempTable;
               else
                   FuturesTable = [FuturesTable; tempTable];
               end
               clear tempTable;
           end
       end
       
       function translateOptions(TT)
           % filter by asset class: only Equity-like assets
           ptfNumber = numel(TT.OptionsLabels);
           OptionsTable = [];
           
           for i =1:ptfNumber
               tempTable = TT.mainTable(strcmp(TT.mainTable.PORTFOLIOID, TT.OptionsLabels(i)),:);
               if i==1
                   OptionsTable = tempTable;
               else
                   OptionsTable = [OptionsTable; tempTable];
               end
               clear tempTable;
           end
       end
   end
end