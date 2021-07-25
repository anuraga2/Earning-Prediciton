#%%
import saspy
import pandas as pd
from IPython.display import HTML

sas = saspy.SASsession(cfgname='winlocal')


# %%
sas.saslib(libref='mydata', path=r"C:\Users\vanand\OneDrive\Research\Active\Forecasting earnings magnitudes\Sample creation")


#%%
df = sas.sd2df_CSV(table='CaoYouSample', libref='mydata')
df.to_parquet('CaoYouSample.parquet', engine='pyarrow')