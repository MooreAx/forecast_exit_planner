# tranform data frames into objects

import pandas as pd
from .simulation import Simulation
from .inventory import Inventory
from .read_data import df_forecast, df_inv_med, df_board_inventory, df_inv_rec_stamped, df_inv_rec_unstamped, df_rat_list
from .globals import *

from collections import namedtuple

#for testing
sim = Simulation(start_date = FCSTART)

#tuple-keyed dict for forecast:
ForecastKey = namedtuple("ForecastKey", ["part", "prov", "channel", "week"])
ForecastVal = namedtuple("ForecastVal", ["qty", "pod"])

forecast_dict = {
    ForecastKey(part=row['part'], prov=row['prov'], channel=row['channel'], week=row['date']):
    ForecastVal(qty=int(row['fc']), pod=row['pod'])
    for _, row in df_forecast.iterrows()
}

#lists for inventory

inv_med_list = [
    Inventory(
        part = row['part'],
        prov = 'MED',
        channel = 'MED',
        lot = row['lotnum'],
        manufactured = row['manufactured'],
        qty = int(row['available']),
        sim = sim
    )
    for _, row in df_inv_med.iterrows()
]

inv_rec_stamped_list = [
    Inventory(
        part = row['part'],
        prov = row['pool'],
        channel = 'REC',
        lot = row['lotnum'],
        manufactured = row['manufactured'],
        qty = int(row['available']),
        sim = sim
    )
    for _, row in df_inv_rec_stamped.iterrows()
]

inv_any_unstamped_list = [
    Inventory(
        part = row['part'],
        prov = 'ANY',
        channel = 'ANY',
        lot = row['lotnum'],
        manufactured = row['manufactured'],
        qty = int(row['available']),
        sim = sim
    )
    for _, row in df_inv_rec_unstamped.iterrows()
]

board_inventory_list = [
    Inventory(
        part = str(row['part_number']),
        prov = str(row['province']),
        channel = 'REC',
        lot = 'board_inv',
        manufactured = datetime(2100, 1, 1).date(),  #future date = always fresh
        qty = row['ttl_pipeline'],
        sim = sim
    )
    for _, row in df_board_inventory.iterrows()
]




#rat list
rat_list = df_rat_list.iloc[:,0].tolist()