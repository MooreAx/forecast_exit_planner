#main simulation loop

from datetime import datetime
from pprint import pprint

#get objects
from .build_objects import (
    inv_med_list, inv_rec_stamped_list, inv_rec_unstamped_list, 
    forecast_dict, rat_list, ForecastKey, sim, board_inventory_list
)

sim.date = datetime(2025, 7, 14).date()

prov_list = 'BC,AB,SK,MB,ON,QC,NB,NS,PE,NL,MED'.split(',')
channel_list = 'MED,REC'.split(',')

#function to fifo inventory from lists
def fifo_inventory_list(inv_list, part, prov, channel, pod, demand):
    available_inv = [
        inv for inv in inv_list
        if (
            inv.part == part 
            and inv.prov == prov 
            and inv.channel == channel
            and inv.qty > 0 
            and inv.age_days <= pod
        )
    ]

    available_inv.sort(key=lambda inv: inv.manufactured)
    remaining = demand
    for inv in available_inv:
        if remaining == 0:
            break

        available = inv.qty
        used = min(available, remaining)
        inv.qty -= used
        remaining -= used

    return remaining

#pprint(forecast_dict)

for _ in range(100):
    for part in rat_list:
        for prov in prov_list:
            for channel in channel_list:

                #get forecast            
                key = ForecastKey(part=part, prov=prov, channel=channel, week=sim.date)
                fcval = forecast_dict.get(key)

                if fcval: #key match
                    pod = fcval.pod
                    demand = fcval.qty

                    remaining = fifo_inventory_list(board_inventory_list, part, prov, channel, pod, demand)
                    remaining = fifo_inventory_list(inv_med_list, part, prov, channel, pod, remaining)
                    remaining = fifo_inventory_list(inv_rec_stamped_list, part, prov, channel, pod, remaining)
                    remaining = fifo_inventory_list(inv_rec_unstamped_list, part, prov, channel, pod, remaining) #unstamped should also be available to medical

                    if remaining == 0:
                        print(f'{sim.date}, {part}, {prov} filled')
                    elif remaining == demand:
                        print(f'{sim.date}, {part}, {prov} unfilled')
                    elif remaining > 0:
                        print(f'{sim.date}, {part}, {prov} part filled')
                        

                else: #no key match
                    continue
    sim.advance_week()
