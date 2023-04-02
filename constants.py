from solid import *
from solid.utils import *

import random

def randc():
    colours = [
        random.uniform(0.3, 1),
        random.uniform(0.3, 1),
        random.uniform(0.3, 1),
    ]
    return lambda model : color(colours, 0.7)(model)
