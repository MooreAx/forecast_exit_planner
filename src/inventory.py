from .simulation import Simulation
import copy

class Inventory:
    def __init__(self, part, prov, channel, lot, manufactured, qty, sim):
        self.part = part
        self.prov = prov
        self.channel = channel
        self.lot = lot
        self.manufactured = manufactured
        self.qty = qty
        self.sim = sim # composition: reference to the simulation

    @property
    def age_days(self):
        return (self.sim.date - self.manufactured).days

    def drawdown(self, amount):
        used = min(self.qty, amount)
        self.qty -= used
        return used