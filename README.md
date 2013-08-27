TShL
====

## For Support visit
## https://github.com/NikolayRag/TShL
## ---------------------------------------------------------------------------
## 	  TShL - simple IDE and execution environment for TCL/TK
##    Copyright (C) 2005(or earlier) Nikolay Ragozin
##
##    This program was never intended to be public and was built in inspiration
##    of 3dsMax Script environment for studying TCL and for my own needs.
##    It's quite stable, but have a dozen known bugs and unfinished features.
##    Futher support and development is chanced to be close to zero,
##    as I'm not interested in TCL no more. Also any incoming heed is welcome.
##
##    This program is supplied WITHOUT ANY WARRANTY; without even the implied
##    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
##
##    This program is free software: you can redistribute it and/or modify
##    it under the terms of the GNU General Public License as published by
##    the Free Software Foundation, either version 3 of the License, or
##    (at your option) any later version.
##    See the GNU General Public License for more details
##    http://www.gnu.org/licenses/gpl-3.0.html
##
## ---------------------------------------------------------------------------


------ v1.0

navigation
check brace
puts
paste - see cursor
clean output window
tab selection
font
context help
file revert
RECENT FILES
search
remember TAB
watch
save and load internal state: 
	window separator pos, 
	geometry, 
	pos, 
	font, 
	wrap state, 
	opened filename, 
	search/replace word, 
	start mode,
option for:
	output wrap,
	help file location,
	start option - new, recent, load dialog

######################################################

------ v1.1

line/selection, all - execution/expression
accumulated execution
select all
undo/redo

statusline - issaved status

Save, new, load - behavior
exit behavior - ync/save
kill all slaves

+multiline execution with ability to break accumulation
+replace
+replace all
+search/replace in selection

todo:
(probably never, go as breef list of unavailability)

-separate immidiate forward, inblock (current) and global brace checking
-check braces while inside quotes
-embedded comments and comment splitfield
-embedded metadata:
	-position
	-font
	-search/replace
	-linked words
	-selections/markers
-step execution with echo mode
-linked words
-selection undo/redo
-position/selection from/to hold buffer
-selections/markers list from/to hold buffer
-quick execution of selection/marker from list
-tab size
-colorer
-Custom key bindings

-statusline - size, pos, markers
-improve pgUp/Dn at nearly top/bottom

-kill all slaves - check

-backup & time backup
-construct adding/predicting
-double braces & quotes creation (Shift+Control+brace)
-one-level braces jumping (by TAB)
-nested braces jumping by (Ctrl+Tab)
option for:
	-backup file
	-reserved words

-shortcut for properly finish accumulator
-make switchable list of Expression execution
improve statusbar:
	-search fwd(+), back
	+acc finish
	+entry for expression execution

-----known bugs:

*watch throws an error sometime on arrays
*wish instantiates as parasite process sometimes on open pipes become invalid
*Search is incomplete but working

######################################################

------ this is for v2.0

-multiwindow and multidocument
	1) one document could be splitted within several windows by meta-lang.
		*templates for meta-filtering
	2) different files for different windows
	3) code queue list
		*active/inactive
	4) separate comments to side-window

	Something like:
	| doc1 |	doc2	   | doc3 |	<- queue of exec
		|part1|part2|partn|		<- different viewports of one document.

-multiclient
-remote client
-?callable independent extensions
-?preprocessor (v2?)
-highlite error places
------
------Meta-filtering:
#tshlmList name1 name2 ...
	*block pages queue definition

###tshlmSplit Name
...code...
###tshlmSplitEnd
	*block for displaying in separate window

###tshlmComment type description
	*definition of typed comments, like todo, debug, memo etc.

