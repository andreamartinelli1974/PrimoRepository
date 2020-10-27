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