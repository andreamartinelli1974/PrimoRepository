function Output = read_broker_data(b_params)

    % this function is designed to read and process the Excel files provided by
    % Facset containing advice from brokers. The function detects new files
    % in the provided data folder and reads them. To keep the history of the
    % signals, at each call the function saves a .mat file with all relevant
    % information. the output is a table with all the historical signals, the
    % trade date, the tickers of the stocks and the vintage number.

    % the input parameters are:
    %
    % b_params.data_dir = the folder where the excel files from facset are
    %
    % b_params.signal_history_file = the name of the excel file with the complete
    %                                history of the data (if this file is not
    %                                available the function will create a new
    %                                file with the specified name and will use
    %                                it for future calls)
    %
    % b_params.use_previous_n_days = the function use the recomandations from n
    %                                previous days to compute the signal in the
    %                                output table

    % the outputis a table with 5 columns:
    % TradeDate, TickerBBG, Broker, Signal, Vintage.

    % input params
    data_dir = b_params.data_dir;
    signal_history_file = b_params.signal_history_file;
    use_previous_n_days = b_params.use_previous_n_days;
    DataFromBBG = b_params.DataFromBBG;

    % check for new files (and for the storing .mat file)
    dir_content = dir([data_dir,'*.xlsx']);
    files_to_check = {dir_content.name};
    new_files = [];

    old_data = [];
    InputTables = [];
    newlastUpdate = NaT(1);

    if isfile('DataStoring.mat')
        load('Datastoring.mat');
        lastUpdate = DataStoring.lastUpdate;
        signal_table = DataStoring.signal_table;
        old_files = DataStoring.filenames;
        new_files = setdiff(files_to_check,old_files);
        if ~isempty(new_files)
            % deal with the new files
            disp('new files found');
            new_names = regexprep(new_files,'[^a-zA-Z0-9]','_');
            new_names = erase(new_names,'_xlsx');
        else
            disp('no new files');
            new_files = {};
        end
    else
        DataStoring.DataTable = [];
        new_files = files_to_check;
        new_names = regexprep(files_to_check,'[^a-zA-Z0-9]','_');
        new_names = erase(new_names,'_xlsx');
        lastUpdate = datetime(1,'ConvertFrom','datenum');

        %load Signal file (if exist)
        if isfile(signal_history_file)
            opts = detectImportOptions(signal_history_file);
            in_table = readtable(signal_history_file,opts);
            signal_table = in_table(:,1:5);
            VarNames = signal_table.Properties.VariableNames;
            signal_table.(VarNames{1}).Format = 'dd-MMM-yyyy';
            DataStoring.signal_table = signal_table;
            last_vintage = signal_table.Vintage(end);
        else
            disp('***   WARNING   ***');
            disp('No Signal History excel file found');
            disp('a new signal history will be created');
            disp('starting from the rating file found in \Data');
        end
    end

    DataStoring.filenames = files_to_check';

    if numel(new_files)>0
        % get data
        for i = 1:numel(new_names)
            % read the table
            opts = detectImportOptions([data_dir,new_files{i}]);
            newTable = readtable([data_dir,new_files{i}],opts);

            %%% TO DO: CHOSE ONE OF THE TWO DATE %%%
            % read the date from the file name
            index   = strfind(new_names{i}, '_');
            S       = new_names{i}((index(end))+1:end);
            StrDate = [S(1:4), '-', S(5:6), '-', S(7:8)];
            datefromname(i) = datetime(StrDate,'InputFormat','yyyy-MM-dd');

            % read the date from "last modification"
            FileInfo = dir([data_dir,new_files{i}]);
            TimeStamp(i) = datetime(FileInfo.date);
            TimeStamp.Format = 'dd-MMM-yyyy';

            % insert the date in the table
            n_row = size(newTable,1);
            newcol = repmat(datefromname(i),n_row,1);
            % newcol = repmat(TimeStamp(i),n_row,1);
            concTable = table(newcol,'VariableNames',{'Date'});
            newTable = [concTable, newTable];

            % store data in InputTables
            InputTables.(new_names{i}).date = datefromname(i);
            InputTables.(new_names{i}).date2 = TimeStamp(i);
            InputTables.(new_names{i}).rawTable = newTable;

            % store table in DataStoring
            DataStoring.DataTable = [DataStoring.DataTable; newTable];
            newlastUpdate = max(datefromname);
            DataStoring.lastUpdate = newlastUpdate;
            clear newTable;
        end
    end


    %% Data manipulation

    if newlastUpdate>lastUpdate
        % to create a matrix with the relavant date (the last one and the
        % use_previous_n_days days before)
        index_date = [];
        date_stored = unique(DataStoring.DataTable.Date);
        date_to_find = date_stored(end-use_previous_n_days+1:end,:);

        for i = 1:use_previous_n_days
            index_d= find(DataStoring.DataTable.Date == date_to_find(i));
            index_date = [index_date; index_d];
            clear index_d;
        end
        Table_to_analyze = DataStoring.DataTable(index_date,:);

        % get brockers names
        broker_names = {};

        names = Table_to_analyze.Properties.VariableNames;
        index_tgp = find(contains(names,'TGP'));
        index_eps = find(contains(names,'EPS'));
        index_rating = find(contains(names,'RATING'));
        min_names = min([index_tgp,index_eps,index_rating]);
        max_names = max([index_tgp,index_eps,index_rating]);
        broker_names = [broker_names, names(min_names:max_names)];

        broker_names = erase(broker_names, 'TGP');
        broker_names = erase(broker_names, 'EPS');
        broker_names = erase(broker_names, 'RATING');
        broker_names = erase(broker_names, '_');

        broker_names = unique(broker_names');

        % get company data
        company_name = {};
        company_name = unique(Table_to_analyze.Name);

        % read the EPS & RATING values for any name
        for i = 1:numel(company_name)

            c_names = Table_to_analyze.Name;
            index_cmp = find(contains(c_names,company_name{i}));

            for j = 1:numel(broker_names)
                b_names = Table_to_analyze.Properties.VariableNames;
                index_eps = find(contains(b_names,[broker_names{j},'_EPS']));
                index_rating = find(contains(b_names,[broker_names{j},'_RATING']));
                signal_eps = sum(Table_to_analyze{index_cmp,index_eps});
                signal_rating = sum(Table_to_analyze{index_cmp,index_rating});

                % condition on signal
                if signal_eps>=1 && signal_rating>=1
                    condition = true;
                    signal_to_wrt = 1;
                elseif signal_eps<=-1 && signal_rating<=-1
                    condition = true;
                    signal_to_wrt = -1;
                else
                    condition = false;
                end

                if condition % verified

                    %get ticker from bbg
                    isin = unique(Table_to_analyze.ISIN(index_cmp));

                    fields2download = {'dx895'};

                    uparam.DataFromBBG = DataFromBBG;
                    uparam.ticker = strcat(isin{1},' Equity');
                    uparam.fields = fields2download;
                    uparam.override_fields = [];
                    uparam.BBG_SimultaneousData = [];
                    uparam.FXE = false(1);

                    U = Utilities(uparam);
                    U.GetBBG_StaticData;

                    ticker = cellstr([U.Output.BBG_getdata.dx895{1}, ' Equity']);

                    % build the output table row to append to the output table.
                    if exist('signal_table','var')
                        VarNames = signal_table.Properties.VariableNames;
                        row_to_add = table(newlastUpdate,ticker,broker_names(j),signal_to_wrt,last_vintage+1);
                        row_to_add.Properties.VariableNames = VarNames;
                        signal_table = [signal_table; row_to_add];
                        %%% to do: write the new signal_history_file
                        %%% trying to append the new data to the old excel table
                    else
                        VarNames = {'TradeDate', 'TickerBBG', 'Broker', 'Signal', 'Vintage'};
                        last_vintage = 0;
                        row_to_add = table(newlastUpdate,'ticker',broker_names{j},signal,last_vintage+1);
                        row_to_add.Properties.VariableNames = VarNames;
                        signal_table = [signal_table; row_to_add];
                        xlswrite(signal_history_file,signal_table);
                    end
                end
                % end of condition
            end
        end
        DataStoring.signal_table = signal_table;
    end
    
    % save & output
    save('DataStoring.mat', 'DataStoring');
    Output = signal_table;

end