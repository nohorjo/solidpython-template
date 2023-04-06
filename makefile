SHELL:=/bin/bash

SOURCES=$(shell grep -l scad_render_to_file *.py)

define GEN_DEPS
import os
import re
import sys

filename = sys.argv[1]
importPattern = re.compile("^from \w+ import")

with open(filename) as f:
    importLines = [ line for line in f if importPattern.match(line) ]
    importLines = map(lambda l: l.split()[1] + ".py", importLines)
    importLines = [ imp for imp in importLines if os.path.isfile(imp) ]

    with open(".%s.dep"% filename[:-3], "w") as f:
        f.write("%s: %s"% (filename, " ".join(importLines)))

endef
export GEN_DEPS

define UPDATE
import os
import re
import sys

importPattern = re.compile("^from \w+ import")

def update_deps(filename, skip_deps):
  if filename[0:2] == './':
    filename = filename[2:]

  print("Executing " + filename)
  os.system("python3 " + filename)

  with open(filename) as f:
      importLines = [ line for line in f if importPattern.match(line) ]
      importLines = map(lambda l: l.split()[1], importLines)

      for imp in importLines:
          if os.path.isfile(imp + ".py"):
              depsfile = ".%s.isdep"% imp
              toAdd = filename + "\n"
              with open(depsfile, 'a+') as df:
                  df.seek(0)
                  if not toAdd in df:
                      df.write(toAdd)

  isdep = ".%s.isdep"% filename[:-3]

  try:
    f = open(isdep)
    deps = list(map(lambda x: x.strip(), open(isdep)))
    for line in deps:
      if line not in skip_deps and os.path.isfile(line):
        update_deps(line, skip_deps + deps)
    f.close()
  except FileNotFoundError:
    pass

update_deps(sys.argv[1], [])
endef
export UPDATE

define NEW_MODULE
read -p "Enter module name: " mn
echo "
from solid import *
from solid.utils import *

from constants import *
from super_hole import *

def $$mn():
  model = cube([1, 2, 3])

  return model

if __name__ == '__main__':
  model = $$mn()

  scad_render_to_file(model, '_%s.scad'% __file__.split('/')[-1][:-3])

" > $$mn.py
endef
export NEW_MODULE

.PHONY: all clean new scad watch

all: $(patsubst %.py,stl/%.stl,$(SOURCES))

scad: $(patsubst %.py,_%.scad,$(SOURCES))

.%.dep: %.py
	python -c "$$GEN_DEPS" $<

-include $(patsubst %.py,.%.dep,$(SOURCES))

_%.scad: %.py
	python -c "$$UPDATE" $<
	python $<

stl/%.stl: _%.scad
	openscad -D '$$fn=100' -m make -o $@ $< || echo -e "\033[1;41mFAIL\033[0m $@"

clean:
	rm stl/* *.scad .*.scad .*.dep .*.isdep

new:
	bash -c "$$NEW_MODULE"

watch:
	inotifywait -m --format '%w' -e close_write ./*.py | while read FILE; \
		do python -c "$$UPDATE" "$$FILE"; \
	done
