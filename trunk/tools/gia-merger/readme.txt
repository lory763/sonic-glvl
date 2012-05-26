gia-merger
==========

Merges *_shadowmap and *_lightmap files into a single *_gia PNG file, to be used
as a GIA map in Sonic Generations. It scans the "source" folder for these files
and produces a file located in the "output" folder.

Usage: 

* Drop your PNG files appropiately called <name>_lightmap.png and <name>_shadowmap.png(the baking 
script lets you select these prefixes), then run the gia-merger.exe program.

* When it's done, check out the output folder for the <name>_gia.png, that you should copy back
to your Importing Scene folder(not to the editor's GIA folder).

A .bat is provided to delete the contents of both folders before doing a new conversion.