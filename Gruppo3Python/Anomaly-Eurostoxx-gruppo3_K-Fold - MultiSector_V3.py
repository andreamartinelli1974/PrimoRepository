
""" Progetto_gruppo3.ipynb
"""
#  Sector outlier detector for EuroStoxx 600 companies

#%% IMPORT SECTION
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.tree import DecisionTreeClassifier 
from sklearn.ensemble import RandomForestClassifier
from sklearn import ensemble 
from sklearn import tree

#%% DIRECTORY SETTINGS
# Change work directory
os.chdir('//srv0001/Risorse/Public/Gruppo3-Python')
cwd = os.getcwd()
print(cwd)


#%% PREPARE FUNCTION
def prepare_data(data):
   
    features = data.drop(["REF_DATE", "SEDOLCHK", "ICB_INDUSTRY_NUM", "ICB_SECTOR_NUM"], axis=1).astype("float64")
        
    return features

#%% IMPORT DATA
#Import .csv
clean_data = pd.read_csv(r'Data/clean2.csv', sep=',')
companynames = pd.read_csv(r'Data/companynames.csv', sep=',')
companynames = companynames.drop_duplicates(subset = "SEDOLCHK")
print(clean_data.head(10))

referenceDate = clean_data["REF_DATE"].drop_duplicates().reset_index(drop = True)

print(referenceDate.head(10))

sectors_dict = {'1':'Oil & Gas','1000':'Basic Materials','2000':'Industrial',
'3000':'Consumer Good','4000':'Health Care','5000':'Consumer Services',
'6000':'Telecomunications','7000':'Utilities','8000':'Financials',
'9000':'Technology'}

# K fold using GridSearchCV
from sklearn.model_selection import GridSearchCV

features = prepare_data(clean_data)

x = features
y = clean_data['ICB_INDUSTRY_NUM']

parameters = {'max_depth':range(3,25)}
clf = GridSearchCV(tree.DecisionTreeClassifier(), parameters, n_jobs=4)
clf.fit(X=x, y=y)
tree_model = clf.best_estimator_
print (clf.best_score_, clf.best_params_) 

#%% K-FOLD VALIDATION
valid = clean_data.to_numpy(copy=True)
N = valid.shape[0]
K = 10                                         # number of folds
preds_kfold = np.empty(N)
folds = np.random.randint(0, K, size=N)

for idx in np.arange(K):
    # For each fold, break your data into training and testing subsets
    data_train = pd.DataFrame(valid[folds != idx,:],columns=['REF_DATE','SEDOLCHK','SIMPLE_TOT_RET','COMPOUND_TOT_RET','FIVE_YR_VOLATILITY_M','FIVE_YR_VOLATILITY_W','ADY','AERR','AGRE','APE','CGR','CV3Y_EPS','CV3Y_EREV_FY1','CV3Y_REP_EPS','CV3Y_REV_MARK','CV5Y_EPS','CV6M_P','CV6M_PM6M','DEBT_MKT_CAP','DY_FWD','DY_TRL','EBIT_SALES','ECM','EEREV','EPS_SIGMA','EPSDISP','EREV','F2GRE','FDY','FERR','FGRE','FPE','FWD_ECM','FWD_GRE','LRE','MKT_CAP_SALES','NM','PB','PCF','PCTCHG_DPS','PCTCHG_EBIT','PCTCHG_EBIT_MARGIN','PCTCHG_EBITDA','PCTCHG_EQUITY','PCTCHG_NET_DEBT','PCTCHG_NM','PCTCHG_PRE_TAX_PROFIT','PCTCHG_ROE','PCTCHG_SALES','PCTCHG_UL_SALES','PE_FWD','PE_TRL','PM6M','RC1MEEREV','RC1MEREV','REC_MARK_1M','REC_MARK_3M','REV_MARK_1M','REV_MARK_3M','REV_STD_MARK','ROE','TRL_ECM','TRL_GRE','TURNOVER_1M','UL_SALES','PB_PCF_1','PB_PCF_2', 'ICB_INDUSTRY_NUM', 'ICB_SECTOR_NUM'])
    data_test  = pd.DataFrame(valid[folds == idx,:],columns=['REF_DATE','SEDOLCHK','SIMPLE_TOT_RET','COMPOUND_TOT_RET','FIVE_YR_VOLATILITY_M','FIVE_YR_VOLATILITY_W','ADY','AERR','AGRE','APE','CGR','CV3Y_EPS','CV3Y_EREV_FY1','CV3Y_REP_EPS','CV3Y_REV_MARK','CV5Y_EPS','CV6M_P','CV6M_PM6M','DEBT_MKT_CAP','DY_FWD','DY_TRL','EBIT_SALES','ECM','EEREV','EPS_SIGMA','EPSDISP','EREV','F2GRE','FDY','FERR','FGRE','FPE','FWD_ECM','FWD_GRE','LRE','MKT_CAP_SALES','NM','PB','PCF','PCTCHG_DPS','PCTCHG_EBIT','PCTCHG_EBIT_MARGIN','PCTCHG_EBITDA','PCTCHG_EQUITY','PCTCHG_NET_DEBT','PCTCHG_NM','PCTCHG_PRE_TAX_PROFIT','PCTCHG_ROE','PCTCHG_SALES','PCTCHG_UL_SALES','PE_FWD','PE_TRL','PM6M','RC1MEEREV','RC1MEREV','REC_MARK_1M','REC_MARK_3M','REV_MARK_1M','REV_MARK_3M','REV_STD_MARK','ROE','TRL_ECM','TRL_GRE','TURNOVER_1M','UL_SALES','PB_PCF_1','PB_PCF_2', 'ICB_INDUSTRY_NUM', 'ICB_SECTOR_NUM'])
    # PREPARE FEATURES
    features = prepare_data(data_train)
    #print(features)

    for col in data_train.columns:
        if data_train[col].dtype==object and col!='SEDOLCHK':
            data_train[col]=pd.to_numeric(data_train[col],errors='coerce')
        
    for col in data_test.columns:
        if data_test[col].dtype==object and col!='SEDOLCHK':
            data_test[col]=pd.to_numeric(data_test[col],errors='coerce')
        
    # SINGLE TREE
    model = tree.DecisionTreeClassifier(max_depth =  clf.best_params_)
    model.fit(features, data_train["ICB_INDUSTRY_NUM"])
    
    print(model.score(prepare_data(data_train), data_train["ICB_INDUSTRY_NUM"]))
    print(model.score(prepare_data(data_test), data_test["ICB_INDUSTRY_NUM"]))

#plt.figure(figsize=[30.0, 30.0])
#tree.plot_tree(model, feature_names=features.columns)

#%% GET THE OUTLIERS SEDOLCHK & names
predicted = model.predict(prepare_data(data_test))
g_truth = data_test["ICB_INDUSTRY_NUM"].to_numpy(copy=True)

outliers_sedol = pd.DataFrame(data_test["SEDOLCHK"])
outliers_sedol['ICB_INDUSTRY_NUM'] = data_test["ICB_INDUSTRY_NUM"]
outliers_sedol['PREDICTED'] = predicted

rowtodrop = np.where(predicted == g_truth)[0]

outliers_sedol = outliers_sedol.drop(outliers_sedol.index[rowtodrop])

outliers = outliers_sedol.merge(companynames, left_on='SEDOLCHK', right_on='SEDOLCHK')

outliers["ICB_INDUSTRY_NUM"] = outliers["ICB_INDUSTRY_NUM"].astype(str)
outliers["ICB_INDUSTRY_NUM"] = outliers["ICB_INDUSTRY_NUM"].map(sectors_dict)
outliers["PREDICTED"] = outliers["PREDICTED"].astype(str)
outliers["PREDICTED"] = outliers["PREDICTED"].map(sectors_dict)

print(outliers)

outliers.to_excel(excel_writer = 'Tree_Outliers.xlsx')

#%% PREDICT ON LAST MONTH

test_last_month = clean_data[(clean_data.REF_DATE==20191129)].copy()

predicted_last = model.predict(prepare_data(test_last_month))
g_truth_last = test_last_month["ICB_INDUSTRY_NUM"].to_numpy(copy=True)

outliers_sedol_last = pd.DataFrame(test_last_month["SEDOLCHK"])
outliers_sedol_last['ICB_INDUSTRY_NUM'] = test_last_month["ICB_INDUSTRY_NUM"]
outliers_sedol_last['PREDICTED'] = predicted_last

rowtodrop_last = np.where(predicted_last == g_truth_last)[0]

outliers_sedol_last = outliers_sedol_last.drop(outliers_sedol_last.index[rowtodrop_last])

outliers_last = outliers_sedol_last.merge(companynames, left_on='SEDOLCHK', right_on='SEDOLCHK')

outliers_last["ICB_INDUSTRY_NUM"] = outliers_last["ICB_INDUSTRY_NUM"].astype(str)
outliers_last["ICB_INDUSTRY_NUM"] = outliers_last["ICB_INDUSTRY_NUM"].map(sectors_dict)
outliers_last["PREDICTED"] = outliers_last["PREDICTED"].astype(str)
outliers_last["PREDICTED"] = outliers_last["PREDICTED"].map(sectors_dict)

print(outliers_last)

outliers_last.to_excel(excel_writer = 'Tree_Outliers_last_month.xlsx')


#%% RANDOM FOREST
forest = ensemble.RandomForestClassifier(n_estimators=50, bootstrap=True, max_features=None)
forest.fit(features, data_train["ICB_INDUSTRY_NUM"])
print(forest.score(prepare_data(data_train), data_train["ICB_INDUSTRY_NUM"]))
forest.score(prepare_data(data_test), data_test["ICB_INDUSTRY_NUM"])   

#%% GET THE OUTLIERS SEDOLCHK & names
predicted_f = forest.predict(prepare_data(data_test))
g_truth_f = data_test["ICB_INDUSTRY_NUM"].to_numpy(copy=True)

outliers_sedol_f = pd.DataFrame(data_test["SEDOLCHK"])
outliers_sedol_f['ICB_INDUSTRY_NUM'] = data_test["ICB_INDUSTRY_NUM"]
outliers_sedol_f['PREDICTED'] = predicted_f

rowtodrop_f = np.where(predicted_f == g_truth_f)[0]

outliers_sedol_f = outliers_sedol_f.drop(outliers_sedol_f.index[rowtodrop_f])

outliers_f = outliers_sedol_f.merge(companynames, left_on='SEDOLCHK', right_on='SEDOLCHK')

outliers_f["ICB_INDUSTRY_NUM"] = outliers_f["ICB_INDUSTRY_NUM"].astype(str)
outliers_f["ICB_INDUSTRY_NUM"] = outliers_f["ICB_INDUSTRY_NUM"].map(sectors_dict)
outliers_f["PREDICTED"] = outliers_f["PREDICTED"].astype(str)
outliers_f["PREDICTED"] = outliers_f["PREDICTED"].map(sectors_dict)

print(outliers_f)

outliers_f.to_excel(excel_writer = 'Forest_Outliers.xlsx')

#%% GET THE FEATURES IMPORTANCE

def show_features(forest, X, y):
  importances = forest.feature_importances_

  # Calcola deviazione standard per plottare errore
  std = np.std([tree.feature_importances_ for tree in forest.estimators_],
              axis=0)
  indices = np.argsort(importances)[::-1]

  # Print the feature ranking
  print("Feature ranking:")

  for f in range(X.shape[1]):
      print("%d. feature %s (%f)" % (indices[f], features.columns[indices[f]], importances[indices[f]]))

  # Plot the feature importances of the forest
  plt.figure(figsize=(20,20))
  plt.title("Feature importances")
  plt.bar(range(X.shape[1]), importances[indices],
        color="r", yerr=std[indices], align="center")
  plt.xticks(range(X.shape[1]), indices)
  plt.xlim([-1, X.shape[1]])
  plt.show()
  
show_features(forest, features, data_train["ICB_INDUSTRY_NUM"])

#%% PREDICT ON LAST MONTH

test_last_month = clean_data[(clean_data.REF_DATE==20191129)].copy()

predicted_last = forest.predict(prepare_data(test_last_month))
g_truth_last = test_last_month["ICB_INDUSTRY_NUM"].to_numpy(copy=True)

outliers_sedol_last = pd.DataFrame(test_last_month["SEDOLCHK"])
outliers_sedol_last['ICB_INDUSTRY_NUM'] = test_last_month["ICB_INDUSTRY_NUM"]
outliers_sedol_last['PREDICTED'] = predicted_last

rowtodrop_last = np.where(predicted_last == g_truth_last)[0]

outliers_sedol_last = outliers_sedol_last.drop(outliers_sedol_last.index[rowtodrop_last])

outliers_last = outliers_sedol_last.merge(companynames, left_on='SEDOLCHK', right_on='SEDOLCHK')

outliers_last["ICB_INDUSTRY_NUM"] = outliers_last["ICB_INDUSTRY_NUM"].astype(str)
outliers_last["ICB_INDUSTRY_NUM"] = outliers_last["ICB_INDUSTRY_NUM"].map(sectors_dict)
outliers_last["PREDICTED"] = outliers_last["PREDICTED"].astype(str)
outliers_last["PREDICTED"] = outliers_last["PREDICTED"].map(sectors_dict)

print(outliers_last)

outliers_last.to_excel(excel_writer = 'Forest_Outliers_last_month.xlsx')
