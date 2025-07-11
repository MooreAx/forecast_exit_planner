import pandas as pd
import copy

class Simulation:
    def __init__(self, start_date):
        self.date = pd.to_datetime(start_date)
        self.week = 0
    
    def advance_week(self):
        self.date += pd.dateoffset(weeks = 1)
        self.week += 1

    def __deepcopy__(self, memo):
        # Create a new instance of the class (i.e. a copy of it, not a reference)
        return Simulation(self.date)