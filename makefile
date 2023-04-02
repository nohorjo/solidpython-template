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

filename = sys.argv[1]

if filename[0:2] == './':
	filename = filename[2:]

if filename[-3:] == '.py':
	importPattern = re.compile("^from \w+ import")

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
			for line in f:
					if os.path.isfile(line.strip()):
							os.system("python3 " + line)
			f.close()
	except FileNotFoundError:
			pass
endef
export UPDATE

.PHONY: all clean scad watch

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

watch:
	inotifywait -m --format '%w' -e close_write ./*.py | while read FILE; \
		do python -c "$$UPDATE" "$$FILE"; \
		sleep 0.3; \
	done
