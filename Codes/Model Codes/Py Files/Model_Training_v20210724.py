# sklearn imports
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.pipeline import Pipeline, FeatureUnion
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error
from sklearn.impute import SimpleImputer
from sklearn.model_selection import GridSearchCV
from sklearn.externals import joblib

# other imports
import pyarrow.parquet as pq
import pandas as pd
import numpy as np
#import time

# plotly imports
import plotly.graph_objects as go

## Reading the Parquet file and converting it to a pandas dataframe
df = pq.read_table('CaoYouSample.parquet')
df = df.to_pandas()

## Data Cleaning steps before we jump into test - train split and transformations
df_new = df.copy()
rem_cols = ['CONM', 'TIC', 'CUSIP','FiscalYearEnd', 'FYEND_plus_3mos','LPERMNO','FYR','SIC','DATADATE']
df_new.drop(rem_cols, axis = 1, inplace = True)
df_new = df_new.drop_duplicates()
df_new = df_new.dropna()

# Train test split

X_IncomeStmt = ['SALE', 'COGS', 'XSGA', 'XAD', 'XRD', 'DP', 'XINT', 'NOPIO', 'TXT', 'XIDO', 'E', 'DVC']
X_IncomeStmt += [f'{feature}_D1' for feature in X_IncomeStmt]
X_BalanceSheet = ['CHE', 'INVT', 'RECT', 'ACT', 'PPENT', 'IVAO', 'INTAN', 'AT', 'AP', 'DLC', 'TXP', 'LCT', 'DLTT', 'LT', 'CEQ']
X_BalanceSheet += [f'{feature}_D1' for feature in X_BalanceSheet]
X_CashFlowStmt = ['CFO', 'CFO_D1']

X = X_IncomeStmt + X_BalanceSheet + X_CashFlowStmt
y = ['E_F1']

# Running the model trainig code and dumping the model file in the directory
cv_error = {} # Dictionary to store cross validation error data
year_list = [2016, 2015, 2014, 2013, 2012, 2011]
for year in year_list:

    # train split
    train_X = df_new.loc[(df_new['FYEAR'] >= (year-10)) & (df_new['FYEAR'] <= (year-1)), X]
    train_y = df_new.loc[(df_new['FYEAR'] >= (year-10)) & (df_new['FYEAR'] <= (year-1)), y]

    # test split
    test_X = df_new.loc[df_new['FYEAR'] == year, X]
    test_y = df_new.loc[df_new['FYEAR'] == year, y]
    
    parameters = {'max_features':['auto'],'max_depth':[20,25,30,35],'min_samples_leaf':[15,20,25,50]}
    
    # setting up the parameter space
    rf_mod = RandomForestRegressor(n_estimators=500, criterion='mse', oob_score=True, n_jobs=-1, random_state=10)

    # Setting up the Grid Search object
    grid_search = GridSearchCV(rf_mod, parameters, cv=5, n_jobs=-1, scoring='neg_mean_squared_error')

    # Fitting the model
    grid_search.fit(train_X, train_y)

    # declaring empty list to append model training error
    lst = []
    cvres = grid_search.cv_results_

    for mean_score, params in zip(cvres["mean_test_score"], cvres["params"]):
        lst.append((np.sqrt(-mean_score), params))

    # appending the year data to the emp
    if year not in cv_error:
        cv_error[year] = lst

    # declaring a string for the model name
    model_name = str(year)+"rf.pkl"

    # saving the model
    year_mod = grid_search.best_estimator_

    # saving the model to drive
    joblib.dump(year_mod,model_name)

    # print(file name)
    print(model_name)

## Printing out the minimum Cross validation error for each year
for year in year_list:
    
    smallest_error = 1000
    for item in cv_error[year]:
        if item[0] < smallest_error:
            smallest_error = item[0]
            features = item[1]

    print("Year: {}, Least CV Error: {}, features: {}".format(year, smallest_error, features))
