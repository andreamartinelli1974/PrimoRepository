uparams.fields = {'OPT_CHAIN'};
uparams.override_fields = [];
uparams.history_start_date = today();
uparams.history_end_date = today();
uparams.DataFromBBG = DataFromBBG;


uparams.ticker = '/ISIN/US90184L1026';
U = Utilities(uparams);
U.GetBBG_StaticData;

bbg_output = U.Output.BBG_getdata;

newstr = split(bbg_output.OPT_CHAIN{1, 1}{1, 1}," ");
