import inspect

from solid import *

def super_hole(model, name, _debug = False):
    if _debug:
        return debug(model)
    fnpart = inspect.stack()[1].filename[:-3].split('/')[-1]
    fn = '.%s_%s.scad'% (fnpart, name)
    content = """
    module %s() {
    %s
    }
    """% (name, scad_render(model))
    with open(fn, 'w') as f:
        f.write(content)
    return hole()(getattr(import_scad(fn), name)())
