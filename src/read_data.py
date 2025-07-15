#pull forecast & inventory

import pandas as pd
import janitor as jn
from .globals import *


#forecast (and freshness req'ts)
df_forecast = pd.read_csv("intermediates/Forecast.csv", dtype = str).clean_names()

#internal inv
df_inv_med = pd.read_csv("intermediates/Inv_Med.csv", dtype = str).clean_names()
df_inv_rec_stamped = pd.read_csv("intermediates/Inv_Rec_Stamped.csv", dtype = str).clean_names()
df_inv_rec_unstamped = pd.read_csv("intermediates/Inv_Rec_Unstamped.csv", dtype = str).clean_names()

#board inv
df_board_inventory = pd.read_csv("intermediates/binv.csv").clean_names()

#rationalization list
df_rat_list = pd.read_csv("inputs/ratlist.csv", dtype = str).clean_names()


#clean up

df_forecast = (
    df_forecast
    .assign(
        date = lambda x: pd.to_datetime(x['date']).dt.date,
        fc = lambda x: pd.to_numeric(x['fc']),
        pod = lambda x: pd.to_numeric(x['pod']).fillna(float('inf'))
    )
)

def process_inv(df):
    df2 = (
        df
        .assign(
            manufactured = lambda x: pd.to_datetime(x['manufactured']).dt.date,
            age = lambda x: pd.to_numeric(x['age']),
            available = lambda x: pd.to_numeric(x['available'])
        )
    )
    return df2

df_inv_med = process_inv(df_inv_med)
df_inv_rec_stamped = process_inv(df_inv_rec_stamped)
df_inv_rec_unstamped = process_inv(df_inv_rec_unstamped)


# Display the first few rows
print(df_forecast.head())
print(df_inv_med.head())
print(df_inv_rec_stamped.head())
print(df_inv_rec_unstamped.head())
print(df_board_inventory.head())
print(df_rat_list.head())

