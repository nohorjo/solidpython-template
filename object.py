from solid import *
from solid.utils import *

from constants import *
from super_hole import *

if __name__ == '__main__':
  model = cube([1, 2, 3])

  scad_render_to_file(model, '_%s.scad'% __file__.split('/')[-1][:-3])

