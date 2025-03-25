stl_files = case.stl case_mirrored.stl lid.stl lid_mirrored.stl hanger.stl hanger_nut.stl pulley.stl spool_holder_base.stl spool_holder_strut.stl spool_holder_roller.stl

%.stl : buffer.scad
	openscad -o $@ --export-format asciistl --backend Manifold -D "part=\"$(basename $@)\"" buffer.scad

all: $(stl_files)

clean:
	rm -f $(stl_files)
