
""" Progetto_gruppo3.ipynb
"""
#  Sector outlier detector for EuroStoxx 600 companies

#%% IMPORT SECTION
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from random import randint
from sklearn.tree import DecisionTreeClassifier 
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import GridSearchCV
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

for col in clean_data.columns:
        if clean_data[col].dtype==object and col!='SEDOLCHK':
            clean_data[col]=pd.to_numeric(clean_data[col],errors='coerce')
        
companynames = pd.read_csv(r'Data/companynames.csv', sep=',')
companynames = companynames.drop_duplicates(subset = "SEDOLCHK")
print(clean_data.head(10))

referenceDate = clean_data["REF_DATE"].drop_duplicates().reset_index(drop = True)

print(referenceDate.tail(20))

sectors_dict = {'1':'Oil & Gas','1000':'Basic Materials','2000':'Industrial',
'3000':'Consumer Good','4000':'Health Care','5000':'Consumer Services',
'6000':'Telecomunications','7000':'Utilities','8000':'Financials',
'9000':'Technology'}

#%% get the rolling window
alldata = len(referenceDate.index)
months_to_train = 12;

value = np.random.randint(months_to_train+1, alldata, size=1)
    
dateToCheck = referenceDate.loc[value]
startRefDate  = referenceDate.loc[value-months_to_train-1]
endRefDate = referenceDate.loc[value-1]

print(dateToCheck)
                                  
mywindow = clean_data[(clean_data['REF_DATE']>=startRefDate.values[0]) & (clean_data['REF_DATE']<=endRefDate.values[0])]

#%% K fold using GridSearchCV
features = prepare_data(mywindow)

x = features
y = mywindow['ICB_INDUSTRY_NUM']

parameters = {'max_depth':range(20,30)}
clf = GridSearchCV(tree.DecisionTreeClassifier(), parameters, n_jobs=8)
clf.fit(X=x, y=y)
tree_model = clf.best_estimator_

print (clf.best_score_, clf.best_params_) 

#%% FIT THE REAL MODEL

model = tree.DecisionTreeClassifier(max_depth = clf.best_params_.get('max_depth'))
model.fit(features, mywindow['ICB_INDUSTRY_NUM'])

#%% GET THE Baseline (the not well classified assets in trainig set)
baseline = model.predict(prepare_data(mywindow))
base_truth = mywindow["ICB_INDUSTRY_NUM"].to_numpy(copy=True)

base_sedol = pd.DataFrame(mywindow["SEDOLCHK"])
base_sedol['ICB_INDUSTRY_NUM'] = mywindow["ICB_INDUSTRY_NUM"]
base_sedol['PREDICTED_NUM'] = baseline

basetodrop = np.where(baseline == base_truth)[0]

base_sedol = base_sedol.drop(base_sedol.index[basetodrop])

mybase = base_sedol.merge(companynames, left_on='SEDOLCHK', right_on='SEDOLCHK')

mybase["ICB_INDUSTRY_NUM"] = mybase["ICB_INDUSTRY_NUM"].astype(str)
mybase["ICB_INDUSTRY"] = mybase["ICB_INDUSTRY_NUM"].map(sectors_dict)
mybase["PREDICTED_NUM"] = mybase["PREDICTED_NUM"].astype(str)
mybase["PREDICTED"] = mybase["PREDICTED_NUM"].map(sectors_dict)

#%% GET THE OUTLIERS SEDOLCHK & names
test_last_month = clean_data[(clean_data.REF_DATE==dateToCheck.values[0])].copy()
predicted = model.predict(prepare_data(test_last_month))
g_truth = test_last_month["ICB_INDUSTRY_NUM"].to_numpy(copy=True)

outliers_sedol = pd.DataFrame(test_last_month["SEDOLCHK"])
outliers_sedol['ICB_INDUSTRY_NUM'] = test_last_month["ICB_INDUSTRY_NUM"]
outliers_sedol['PREDICTED_NUM'] = predicted

rowtodrop = np.where(predicted == g_truth)[0]

outliers_sedol = outliers_sedol.drop(outliers_sedol.index[rowtodrop])

outliers = outliers_sedol.merge(companynames, left_on='SEDOLCHK', right_on='SEDOLCHK')

outliers["ICB_INDUSTRY_NUM"] = outliers["ICB_INDUSTRY_NUM"].astype(str)
outliers["ICB_INDUSTRY"] = outliers["ICB_INDUSTRY_NUM"].map(sectors_dict)
outliers["PREDICTED_NUM"] = outliers["PREDICTED_NUM"].astype(str)
outliers["PREDICTED"] = outliers["PREDICTED_NUM"].map(sectors_dict)

#print(outliers)
outliers[~outliers.isin(mybase)].dropna()

filename = 'Tree_Outliers_'+str(dateToCheck.values[0])+'.xlsx'
basefile = 'Tree_Baseline_'+str(dateToCheck.values[0])+'.xlsx'

outliers.to_excel(excel_writer = filename)
mybase.to_excel(excel_writer = basefile)


#%% RANDOM FOREST
#K fold using GridSearchCV

parameters = {'n_estimators':range(70,110), 'max_features':range(10,30)}
clf_f = GridSearchCV(ensemble.RandomForestClassifier(), parameters, n_jobs=4)
clf_f.fit(X=x, y=y)
forest_model = clf_f.best_estimator_

print (clf_f.best_score_, clf_f.best_params_) 

#%% FIT THE REAL MODEL
f_estim = clf_f.best_params_.get('n_estimators')
f_maxf = clf_f.best_params_.get('max_features')

forest = ensemble.RandomForestClassifier(n_estimators=f_estim, bootstrap=True, max_features=f_maxf)
forest.fit(features, mywindow["ICB_INDUSTRY_NUM"])

#%% GET THE Baseline (the not well classified assets in trainig set)
baseline_f = forest.predict(prepare_data(mywindow))
base_truth_f = mywindow["ICB_INDUSTRY_NUM"].to_numpy(copy=True)

base_sedol_f = pd.DataFrame(mywindow["SEDOLCHK"])
base_sedol_f['ICB_INDUSTRY_NUM'] = mywindow["ICB_INDUSTRY_NUM"]
base_sedol_f['PREDICTED_NUM'] = baseline

basetodrop_f = np.where(baseline_f == base_truth_f)[0]

base_sedol_f = base_sedol_f.drop(base_sedol_f.index[basetodrop_f])

mybase_f = base_sedol_f.merge(companynames, left_on='SEDOLCHK', right_on='SEDOLCHK')

mybase_f["ICB_INDUSTRY_NUM"] = mybase_f["ICB_INDUSTRY_NUM"].astype(str)
mybase_f["ICB_INDUSTRY"] = mybase_f["ICB_INDUSTRY_NUM"].map(sectors_dict)
mybase_f["PREDICTED_NUM"] = mybase_f["PREDICTED_NUM"].astype(str)
mybase_f["PREDICTED"] = mybase_f["PREDICTED_NUM"].map(sectors_dict)
  
#%% GET THE OUTLIERS SEDOLCHK & names

predicted_f = forest.predict(prepare_data(test_last_month))
g_truth_f = test_last_month["ICB_INDUSTRY_NUM"].to_numpy(copy=True)

outliers_sedol_f = pd.DataFrame(test_last_month["SEDOLCHK"])
outliers_sedol_f['ICB_INDUSTRY_NUM'] = test_last_month["ICB_INDUSTRY_NUM"]
outliers_sedol_f['PREDICTED_NUM'] = predicted_f

rowtodrop_f = np.where(predicted_f == g_truth_f)[0]

outliers_sedol_f = outliers_sedol_f.drop(outliers_sedol_f.index[rowtodrop_f])

outliers_f = outliers_sedol_f.merge(companynames, left_on='SEDOLCHK', right_on='SEDOLCHK')

outliers_f["ICB_INDUSTRY_NUM"] = outliers_f["ICB_INDUSTRY_NUM"].astype(str)
outliers_f["ICB_INDUSTRY"] = outliers_f["ICB_INDUSTRY_NUM"].map(sectors_dict)
outliers_f["PREDICTED_NUM"] = outliers_f["PREDICTED_NUM"].astype(str)
outliers_f["PREDICTED"] = outliers_f["PREDICTED_NUM"].map(sectors_dict)

outliers_f[~outliers_f.isin(mybase_f)].dropna()

filename_f = 'Forest_Outliers_'+str(dateToCheck.values[0])+'.xlsx'
basefile_f = 'Forest_Baseline_'+str(dateToCheck.values[0])+'.xlsx'

outliers_f.to_excel(excel_writer = filename_f)
mybase_f.to_excel(excel_writer = basefile_f)

#%% delete all the relavant variable & dataframe
#date = [dateToCheck,startRefDate,endRefDate]
#del dateToCheck,startRefDate,endRefDate
#del date
#lst = [outliers, mybase, outliers_sedol, base_sedol, basetodrop, rowtodrop, filename, outliers_f,
#mybase_f, outliers_sedol_f, base_sedol_f, basetodrop_f, rowtodrop_f, filename_f, mywindow, features, test_last_month]
#del outliers, mybase, outliers_sedol, base_sedol, basetodrop, rowtodrop, filename, outliers_f,
#mybase_f, outliers_sedol_f, base_sedol_f, basetodrop_f, rowtodrop_f, filename_f, mywindow, features, test_last_month
#del lst
    
    
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
  
show_features(forest, features, mywindow["ICB_INDUSTRY_NUM"])


#%% scatterplot

one_month_data = clean_data[(clean_data.REF_DATE==dateToCheck.values[0])].copy()
colors_dict = {'1':'blue','1000':'red','2000':'green',
'3000':'yellow','4000':'cyan','5000':'purple',
'6000':'orange','7000':'grey','8000':'olive',
'9000':'brown'}

one_month_data["ICB_INDUSTRY_NUM"] = one_month_data["ICB_INDUSTRY_NUM"].astype(str)
one_month_data["COLORS"] = one_month_data["ICB_INDUSTRY_NUM"].map(colors_dict)

n_col=len(one_month_data.columns)

col_to_plot = np.random.randint(2, n_col-2, size=2)
print(col_to_plot[0])

#col1 = one_month_data.columns[col_to_plot[0]]
#col2 = one_month_data.columns[col_to_plot[1]]

col1 = 'PB_PCF_1'
col2 = 'EBIT_SALES'
col2 = 'MKT_CAP_SALES'

x = one_month_data[col1]
y = one_month_data[col2]
color = one_month_data['COLORS']

fig, ax = plt.subplots(figsize=(14, 10))

ax.scatter(x, y, c=color, label=color, s = 100, edgecolors='black')

ax.set_xlabel(col1)
ax.set_ylabel(col2)

#ax.grid(True)

plt.show()

#%% Print Tree outliers 
outliers["PREDICTED_NUM"] = outliers["PREDICTED_NUM"].astype(str)
outliers['COLORS_2'] = outliers["PREDICTED_NUM"].map(colors_dict)

n_col=len(one_month_data.columns)

col_to_plot = np.random.randint(2, n_col-2, size=2)
print(col_to_plot[0])

#col1 = one_month_data.columns[col_to_plot[0]]
#col2 = one_month_data.columns[col_to_plot[1]]

col1 = 'PB_PCF_1'
col2 = 'EBIT_SALES'
col2 = 'MKT_CAP_SALES'

sector = '8000' # to be chosen between 1, 2000,3000 .... ,9000

mysector = one_month_data['ICB_INDUSTRY_NUM'] == sector
toprint = one_month_data[mysector]

outliers_toprint = toprint.merge(outliers, left_on='SEDOLCHK', right_on='SEDOLCHK')

x1 = toprint[col1]
y1 = toprint[col2]
color1 = toprint['COLORS']

x2 = outliers_toprint[col1]
y2 = outliers_toprint[col2]
color2 = outliers_toprint['COLORS_2']

fig, ax = plt.subplots(figsize=(14, 10))

ax.scatter(x1, y1, c=color1, label=color1, s = 100, edgecolors='black')
ax.scatter(x2, y2, c=color2, label=color2, s = 100, edgecolors='black')

ax.set_xlabel(col1)
ax.set_ylabel(col2)

#ax.grid(True)

plt.show()

#%% Print Forest outliers 
outliers_f["PREDICTED_NUM"] = outliers_f["PREDICTED_NUM"].astype(str)
outliers_f['COLORS_2'] = outliers_f["PREDICTED_NUM"].map(colors_dict)

n_col=len(one_month_data.columns)

col_to_plot = np.random.randint(2, n_col-2, size=2)
print(col_to_plot[0])

#col1 = one_month_data.columns[col_to_plot[0]]
#col2 = one_month_data.columns[col_to_plot[1]]

col1 = 'PB_PCF_1'
col2 = 'EBIT_SALES'
col2 = 'MKT_CAP_SALES'

sector = '8000' # to be chosen between 1, 2000,3000 .... ,9000

mysector = one_month_data['ICB_INDUSTRY_NUM'] == sector
toprint = one_month_data[mysector]

outliers_toprint = toprint.merge(outliers_f, left_on='SEDOLCHK', right_on='SEDOLCHK')

x1 = toprint[col1]
y1 = toprint[col2]
color1 = toprint['COLORS']

x2 = outliers_toprint[col1]
y2 = outliers_toprint[col2]
color2 = outliers_toprint['COLORS_2']

fig, ax = plt.subplots(figsize=(14, 10))

ax.scatter(x1, y1, c=color1, label=color1, s = 100, edgecolors='black')
ax.scatter(x2, y2, c=color2, label=color2, s = 100, edgecolors='black')

ax.set_xlabel(col1)
ax.set_ylabel(col2)

#ax.grid(True)

plt.show()