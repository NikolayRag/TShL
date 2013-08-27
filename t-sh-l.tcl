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

#console loopback
if {![info exists argv]} {set argv {}}

set pwd [pwd]
source tshlsupport
package require BWidget

array set helpWords {}
array set ::privState {
	helph {}
	searchRange {1.0 end}
	slave 0
	progName {T-Sh-L v1.0}
	fileName {}
	saved 1
	waitflag 0
	accumulator {}
	accBraces {}
	braces {}
	tempFiles {$::env(temp)/t-sh-l.temporary.tcl}
}

array set ::intState {
	hangFlag 0
	entries {0}
	slaves {0}

	dir {}
	searchword {}
	replaceword {}
	searchBack 0
	searchCase 0
	searchRegExp 0
	searchInSel 0
	searchLink 0
	separator 0.5
	geom {}
	font {{MS Sans Serif} 8}
	outFont {{MS Sans Serif} 8}
	wrap 0
	posX 1
	posY 0
	hScroll 0
	vScroll 0
	selections {}
	recentFiles {}
	backup 1
	autoBackup 1,10
	startMode Recent
	navigateDic {proc 1}
	exprCmd expr
	helpFile {}
}

proc makeUpDraw {} {
	frame .dualCanvas
	frame .topField -bd 1 -rel sunk
	text .outText -width 0 -height 0 -yscrollcommand ".topField.vScr set" -xscrollcommand ".topField.hScr set" -bd 0 -state disabled -wrap none -bg #eeddbb
	.outText tag configure stdout -foreg #000000
	.outText tag configure stderr -foreg #ffffff
	.outText tag configure expr -backg #8080ff
	.outText tag configure exprerr -backg #ff8080
	.outText tag configure eval -foreg #0000ff
	.outText tag configure evalerr -foreg #ff0000
	scrollbar .topField.vScr -command ".outText yview"
	scrollbar .topField.hScr -orient horizontal -command ".outText xview"

	grid .outText -in .topField -column 0 -row 0 -sticky news
	grid .topField.vScr -column 1 -row 0 -sticky news
	grid .topField.hScr -column 0 -row 1 -sticky news

	grid columnconfigure .topField 0 -weight 1
	grid rowconfigure .topField 0 -weight 1

	#
#.mainText
	frame .botField -bd 1 -rel sunk
	text .mainText -width 0 -height 0 -yscrollcommand ".botField.vScr set" -xscrollcommand ".botField.hScr set" -bd 0 -wrap none -undo 1 -bg #ffffff
	.mainText tag con altSel -bac #256ca7 -for white
	.mainText tag con tag1 -bac #eeeeee
	scrollbar .botField.vScr -command ".mainText yview"
	scrollbar .botField.hScr -orient horizontal -command ".mainText xview"
	grid .mainText -in .botField -column 0 -row 0 -sticky news
	grid .botField.vScr -column 1 -row 0 -sticky news
	grid .botField.hScr -column 0 -row 1 -sticky news

	grid columnconfigure .botField 0 -weight 1
	grid rowconfigure .botField 0 -weight 1

	#

	place .topField -x 0 -relwidth 1 -y 0 -relheight 0.5 -height -4 -in .dualCanvas
	place [frame .vSep -height 3 -bd 1 -relief raise -cursor sb_v_double_arrow] -x 0 -relwidth 1 -y -2 -rely 0.5 -height 4 -in .dualCanvas
	place .botField -x 0 -relwidth 1 -y 4 -rely 0.5 -relheight 0.5 -height -4 -in .dualCanvas

	#Pack Layout

	pack .dualCanvas -expand 1 -fill both

	frame .statusLine -relief groove -bd 2 -pady 2 -padx 1
	frame .statusLine.searchWrd -rel gro -bd 1
		pack [label .statusLine.searchWrd.searchLab -text Search:] -side left
		pack [entry .statusLine.searchWrd.searchString -bd 1 -textvariable ::intState(searchword) -takefocus 0] -side left -fill y
			bind .statusLine.searchWrd.searchString <Return> {event generate .mainText <<eFindNext>>}
		pack [frame .statusLine.searchWrd.searchRew -width 16] -side left -fill y
			place [button .statusLine.searchWrd.searchRew.b -font Webdings -text 3 -bd 1 -command {} -takefocus 0] -relh 1 -relw 1
		pack [frame .statusLine.searchWrd.searchFwd -width 16] -side left -fill y
			place [button .statusLine.searchWrd.searchFwd.b -font Webdings -text 4 -bd 1 -command {event generate .mainText <<eFindNext>>} -takefocus 0] -relh 1 -relw 1
	frame .statusLine.accList -rel gro -bd 1
		pack [label .statusLine.accList.accLab -text Acc:] -side left
		pack [entry .statusLine.accList.accDisplay -bd 1 -textvariable ::privState(accBraces) -takefocus 0 -state readonly -font {fixedsys} -width 16] -side left -fill y
		pack [frame .statusLine.accList.accFinish -width 18] -side left -fill y
			place [button .statusLine.accList.accFinish.b -text ")\}\]" -bd 1 -command {event generate .mainText <<eAccFinish>>} -takefocus 0] -relh 1 -relw 1
	frame .statusLine.exprChoice -rel gro -bd 1
		pack [label .statusLine.exprChoice.lab -text Expr:] -side left
		pack [entry .statusLine.exprChoice.string -bd 1 -validate all -textvariable ::intState(exprCmd) -takefocus 0] -side left -fill y

	label .statusLine.savedLab -bd 1 -rel gro -bg green -text S -padx 5
	label .statusLine.posLab -bd 1 -rel gro -text Pos:0.0 -padx 5
	label .statusLine.slaveLab -bd 1 -rel gro -text Slave:Tk -padx 5
	pack .statusLine -fill both
#	pack .statusLine.savedLab .statusLine.posLab .statusLine.slaveLab -side right -padx 1
	pack .statusLine.searchWrd -side left -padx 1 -fill y
	pack .statusLine.savedLab .statusLine.exprChoice .statusLine.accList -side right -padx 1 -fill y
}

proc makeUpMenu {} {
	menu .menuMain
	menu .menuMain.menuFile -title File
	menu .menuMain.menuEdit -title Edit
	menu .menuMain.menuExecute -title Execute
	menu .menuMain.menuTools -title Tools
	menu .menuMain.menuConfig -title Config
	menu .menuMain.menuHelp -title Help

	.menuMain add cascade -menu .menuMain.menuFile -label File
	.menuMain add cascade -menu .menuMain.menuEdit -label Edit
	.menuMain add cascade -menu .menuMain.menuExecute -label Execute
	.menuMain add cascade -menu .menuMain.menuTools -label Tools
	.menuMain add cascade -menu .menuMain.menuConfig -label Config
	.menuMain add cascade -menu .menuMain.menuHelp -label Help

	menu .menuMain.menuRecent -title "Recent Files"
	.menuMain.menuFile add cascade -label Recent -menu .menuMain.menuRecent
	.menuMain.menuFile add separator
	.menuMain.menuFile add command -label New -accelerator Ctrl-N -underline 0 -command {event generate . <<eNew_Doc>>}
	.menuMain.menuFile add command -label Open -accelerator Ctrl-O -underline 0 -command {event generate . <<eOpen_Doc>>}
	.menuMain.menuFile add command -label Revert -underline 0 -command {if {$::privState(fileName) ne {}} {if {[llength [glob -nocomplain $::privState(fileName)]]==1} {prjOpen $::privState(fileName)} else {set ::privState(fileName) {}}}}
	.menuMain.menuFile add separator
	.menuMain.menuFile add command -label Save -accelerator Ctrl-S -underline 0 -command {event generate . <<eSave_Doc>>}
	.menuMain.menuFile add command -label "Save as ..." -accelerator Ctrl-Shift-S -underline 1 -command {event generate . <<eSaveAs_Doc>>}
#!	.menuMain.menuFile add separator
#!	.menuMain.menuFile add command -label Instance
	.menuMain.menuFile add separator
	.menuMain.menuFile add command -label Exit -accelerator Alt-X -underline 1 -command {event generate . <<eExit>>}

	.menuMain.menuEdit add command -label Undo -accelerator Ctrl-Z -underline 0 -command {.mainText edit undo}
	.menuMain.menuEdit add command -label Redo -accelerator Ctrl-Y -underline 0 -command {.mainText edit redo}
	.menuMain.menuEdit add separator
	.menuMain.menuEdit add command -label Copy -accelerator Ctrl-C -underline 0 -command {event generate .mainText <<Copy>>}
	.menuMain.menuEdit add command -label Cut -accelerator Ctrl-X -underline 1 -command {event generate .mainText <<Cut>>}
	.menuMain.menuEdit add command -label Paste -accelerator Ctrl-V -underline 0 -command {event generate .mainText <<Paste>>}
	.menuMain.menuEdit add separator
	.menuMain.menuEdit add command -label "Select All" -accelerator Alt-A -underline 0 -command {event generate .mainText <<eSel_All>>}
	.menuMain.menuEdit add separator
	.menuMain.menuEdit add command -label Find -accelerator Ctrl-F -underline 0 -command {event generate .mainText <<eFind>>}
	.menuMain.menuEdit add command -label "Find Next" -accelerator F3 -underline 5 -command {event generate .mainText <<eFindNext>>}
	.menuMain.menuEdit add command -label Replace -accelerator Ctrl-H -underline 0 -command {event generate .mainText <<eReplace>>}

	.menuMain.menuExecute add command -label "Execute All" -accelerator Ctrl-E -underline 8 -command {event generate .mainText <<eExe_All>>}
	.menuMain.menuExecute add command -label "Execute Selection" -accelerator Ctrl-Return -underline 8 -command {event generate .mainText <<eExe_Chunk>>}
#!	.menuMain.menuExecute add command -label "Step Line"
#!	.menuMain.menuExecute add separator
#!	.menuMain.menuExecute add checkbutton -label "By Line"
	.menuMain.menuExecute add separator
	.menuMain.menuExecute add command -label Reset -accelerator Ctrl-Alt-R -underline 0 -command {event generate .mainText <<eReset>>}

	menu .menuMain.menuExtentions -title Extentions
	.menuMain.menuTools add command -label "Brace More" -accelerator Ctrl-B -underline 0 -command {event generate .mainText <<eBrace>>}
	.menuMain.menuTools add separator
	.menuMain.menuTools add command -label "Watcher" -command {wm deiconify .watchTop}
#	.menuMain.menuTools add separator
#!	.menuMain.menuTools add cascade -label Extentions -menu .menuMain.menuExtentions

	.menuMain.menuConfig add command -label {Preferences} -underline 0 -command {prjPref}
	.menuMain.menuConfig add checkbutton -label "Wrap Output"  -variable ::intState(wrap) -command setWrap
#!	.menuMain.menuConfig add separator
#!	.menuMain.menuConfig add command -label Keys
#!	.menuMain.menuConfig add command -label Extentions

	.menuMain.menuHelp add command -label About -underline 0 -command wndAbout
	.menuMain.menuHelp add separator
	.menuMain.menuHelp add command -label "TCL Help" -accelerator F1
#!	.menuMain.menuHelp add command -label Help -accelerator F2

	. configure -menu .menuMain

	menu .outText.menu -tearoff 0
	.outText.menu add command -label {Copy} -command {event generate .outText <<Copy>>}
	.outText.menu add command -label {Clear} -command {.outText con -state normal; .outText delete 0.0 end; .outText con -state disabled}

	menu .mainText.menu -tearoff 0
	.mainText.menu add command -label {Cut} -command {event generate .mainText <<Cut>>}
	.mainText.menu add command -label {Copy} -command {event generate .mainText <<Copy>>}
	.mainText.menu add command -label {Paste} -command {event generate .mainText <<Paste>>}
}

proc makeUpBind {} {
	proc vSepMot {iupd {per {}}} {
		if {$per eq {}} {
			set h [winfo height .dualCanvas]
			set rely [expr [winfo pointery .dualCanvas]-[winfo rooty .dualCanvas]]
			if $rely<50 {set rely 50}
			if $rely>[expr $h-50] {set rely [expr $h-50]}
			set per [expr 1.*$rely/$h]
		}
		place configure .vSep -rely $per
		if $iupd {
			place configure .topField -relheight $per
			place configure .botField -relheight [expr 1-$per] -rely $per
			update
		}
		set ::intState(separator) $per
	}
	bind .vSep <B1-Motion> {vSepMot 0}
	bind .vSep <Alt-B1-Motion> {vSepMot 1}
	bind .vSep <1> {.vSep configure -rel sunk}
	bind .vSep <ButtonRelease-1> {.vSep configure -rel raise; vSepMot 1}

	bind . <<eNew_Doc>> {
		prjNew
		break
	}
	bind . <<eOpen_Doc>> {
		prjOpen
		break
	}
	bind . <<eSave_Doc>> {
		prjSave
		break
	}
	bind . <<eSaveAs_Doc>> {
		prjSave 1
		break
	}
	bind . <<eExit>> {
		if [checkSaved] {
			set ::intState(geom) [wm geometry .]
			set ::intState(posX) [lindex [split [.mainText index insert] .] 0]
			set ::intState(posY) [lindex [split [.mainText index insert] .] 1]
			set ::intState(hScroll) [lindex [.mainText xview] 0]
			set ::intState(vScroll) [lindex [.mainText yview] 0]
			set ::intState(hangFlag) 0
			setIni
			killSlave
			destroy .
		}
	}
	bind . <<eExe_All>> {
		setSlave 1
		prjExe 0.0 end
		break
	}
	bind . <<eExe_Chunk>> {
		set r [.mainText tag ranges sel]
		if {$r eq {}} {
			prjExe "insert linestart" "insert lineend"
		} else {
			prjExe [lindex $r 0] [lindex $r 1]
		}
		break
	}
	bind . <<eExeExpr>> {
		if {[.mainText tag ranges sel] eq {}} {
			prjExpr "insert linestart" "insert lineend"
		} else {
			eval [concat prjExpr [.mainText tag ranges sel]]
		}
		break
	}
	bind . <<eReset>> {
		setSlave 1
		break
	}

	bind Text <<eSel_All>> {%W tag add sel 1.0 end}
	bind .mainText <<eInsert>> {
		prjInsert %X %Y
		break
	}
	bind .mainText <<eNavigate>> {
		prjNavigate %X %Y
		break
	}
	bind .mainText <<eBrace>> {
		addBrace
	}
	bind .mainText <<eSelShrink>> {
		set selRange [.mainText tag ranges sel]
		if {$selRange eq {}} break
		.mainText tag remove sel [.mainText index [lindex $selRange 0]]
		.mainText tag remove sel [.mainText index "[lindex $selRange 1] -1 chars"]
	}
	bind .mainText <<eSelExpand>> {
		set selRange [.mainText tag ranges sel]
		if {$selRange eq {}} break
		.mainText tag add sel [.mainText index "[lindex $selRange 0] linestart"] [.mainText index "[lindex $selRange 1] lineend"]
	}
	bind .mainText <<eSelWord>> {
		set selRange [.mainText tag ranges sel]
		set selE [set selB [.mainText index insert]]
		if {$selRange ne {}}  {set selB [lindex $selRange 0]; set selE [lindex $selRange 1]}
		set word [.mainText get "$selB -1 chars linestart" "$selB -1 chars"]
		set iB [string length $word]
		set word [join [list $word [.mainText get "$selB -1 chars" $selE]] {}]
		set iE [string length $word]
		set word [join [list $word [.mainText get $selE "$selE lineend"]] {}]
		.mainText tag add sel "insert linestart +[string wordstart $word $iB] chars" "insert linestart +[string wordend $word $iE] chars"
	}
	bind .mainText <Return> {
		set cp [.mainText index insert]
		set l [lindex [split [.mainText index insert] .] 0]
		set maxP [lindex [split [.mainText index "$l.0 -1 lines lineend"] .] 1]
		for {set p 0} {$p<$maxP} {incr p} {if {[.mainText get "$l.0 -1 lines linestart +$p chars"] ne "\t"} break}
		if {([.mainText get "$l.0 -1 lines lineend -1 chars"] eq "\{")&&([.mainText get $l.0] eq "\}")} {
			.mainText insert "$l.0" \n
			for {set i 0} {$i<$p} {incr i} {.mainText insert "$l.0 +1 lines" \t}
			incr p
		}
		.mainText mark set insert $cp
		for {set i 0} {$i<$p} {incr i} {.mainText insert $l.0 \t}
	}
	bind .mainText <<Paste>> {.mainText see insert}
	bind .mainText <Tab> {
		set ranges [.mainText tag ranges sel]
		if {$ranges eq {}} {tk::TextInsert %W \t; break}
		set topR [lindex [split [lindex $ranges 0] .] 0]
		if [lindex [split [lindex $ranges 0] .] 1]>0 {incr topR}
		set botR [lindex [split [lindex $ranges 1] .] 0]
		if [lindex [split [lindex $ranges 1] .] 1]==0 {set botR [expr $botR-1]}
		for {set i $topR} {$i<=$botR} {incr i} {
			.mainText insert $i.0 \t
			.mainText tag add sel $i.0
		}
	}
	bind .mainText <Shift-Tab> {
		set ranges [.mainText tag ranges sel]
		if {$ranges eq {}} {break}
		set topR [lindex [split [lindex $ranges 0] .] 0]
		if [lindex [split [lindex $ranges 0] .] 1]>0 {incr topR}
		set botR [lindex [split [lindex $ranges 1] .] 0]
		if [lindex [split [lindex $ranges 1] .] 1]==0 {set botR [expr $botR-1]}
		for {set i $topR} {$i<=$botR} {incr i} {
			if {[.mainText get $i.0] eq "\t"} {.mainText delete $i.0}
		}
	}
	bind .mainText <<eHelp>> {
		HELP
	}
	bind .mainText <<eAccFinish>> {
		if {$::privState(accumulator)!={}} {
			for {set i [string length $::privState(accBraces)]} {$i>=0} {incr i -1} {append ::privState(accumulator) [switch -- [string index $::privState(accBraces) $i-1] {[} {concat {]}} {(} {concat {)}} "\{" {concat "\}"}]}
			set ::privState(accBraces) {}
			prjExeAcc
		}
	}
	bind .mainText <<eFindNext>> {
		if {$::intState(searchword)!={}} searchAgain else {searchNew 0}
	}
	bind .mainText <<eFind>> {
		searchNew 0
	}
	bind .mainText <<eReplace>> {
		searchNew 1
	}
	bind .outText <3> {
		.outText.menu post [winfo pointerx .] [winfo pointery .]
	}
	bind .mainText <3> {
		.mainText.menu post [winfo pointerx .] [winfo pointery .]
	}

	bind Text <Escape> {if {$::privState(accumulator)!={}} {outPut "Accumulated code flushed\n"}; set ::privState(accumulator) {}; set ::privState(accBraces) {};}
	bind Text <Control-b> {}
	bind Text <Control-f> {}
	bind Text <Control-h> {}
	bind Text <Tab> {continue}
	bind Text <Shift-Tab> {continue}
	bindtags .mainText {all . Text .mainText}
	bindtags .outText {all . Text .outText}

	event add <<eHelp>> <F1>

	event add <<eNew_Doc>> <Control-n>
	event add <<eOpen_Doc>> <Control-o>
	event add <<eSave_Doc>> <Control-s>
	event add <<eSave_Doc>> <F2>
	event add <<eSaveAs_Doc>> <Control-Shift-s>
	event add <<eSaveAs_Doc>> <Control-Shift-S>
	event add <<eExit>> <Alt-F4>

	event add <<eFind>> <Control-f>
	event add <<eFindNext>> <F3>
	event add <<eReplace>> <Control-h>

	event add <<eExe_All>> <Control-e>
	event add <<eExe_Chunk>> <Control-Return>
	event add <<eExeExpr>> <Control-Alt-Return>
	event add <<eReset>> <Control-Alt-r>
	event add <<eSel_All>> <Control-a>

	event add <<eInsert>> <Alt-3>
	event add <<eNavigate>> <Control-3>
	event add <<eBrace>> <Control-b>
	event add <<eSelShrink>> <Control-minus>
	event add <<eSelExpand>> <Control-plus>
#	event add <<eSelWord>> <Control-plus>
}

#####################ProCs From Here######

proc computeSize {outw pages} {
	set wmax 0
	set hmax 0
	update idletasks
	foreach page $pages {
		set w [winfo reqwidth  $page]
		set h [winfo reqheight $page]
		set wmax [expr {$w>$wmax?$w:$wmax}]
		set hmax [expr {$h>$hmax?$h:$hmax}]
	}
	$outw configure -width $wmax -height $hmax
}

proc wndAbout {} {
	modalWnd .topAbout {} {} {
		message $w.what -text "T-Sh-L is a writing and debuging environment tool\nfor Tcl/Tk written on Tcl/Tk\nby Nikolay Ragozin, aug 2002, Moscow." -aspect 300 -justify center
		message $w.andwhat -text "GNU General Public License applied.\n\nAny responsibility for a harm\ndeveloped by this code or\nwith its assistance is rejected." -aspect 300 -justify center
		frame $w.sep -rel sunk -bd 1 -height 2
		pack $w.what $w.sep $w.andwhat -fill both
		focus -force $w
		bind .topAbout <Key> "destroy $w"
		bind .topAbout <FocusOut> "destroy $w"
		wm title $w "About T-Sh-L"
	}
}
proc prjPref {} {
	array set ::tmpIntState [array get ::intState]
	set newPref [
		modalWnd .pref {Ok Cancel} {} {
			wm title $w "Prefs"

			pack [frame $w.chooserFr -bd 2 -rel raise -pady 4 -padx 4] -expand 1 -fill both
			pack [ComboBox $w.cb -values {{Fonts} {Maintenance} {Help}} -editable 0 -modifycmd "$w.f raise \[$w.cb getvalue\]"] -anchor w -in $w.chooserFr

			$w.cb setvalue first
			pack [PagesManager $w.f]

			set f [$w.f add 0]
			$f con -bd 0 -rel groove
			pack [labelframe $f.fOutDef -text {Output Window Font}] -expand 0 -fill both
			set ecmdO [subst -nocommands {$f.fOutDef.sample configure -font [dlist [lindex [$f.fOutDef.fam cget -values] [$f.fOutDef.fam getvalue]] [lindex [$f.fOutDef.size cget -values] [$f.fOutDef.size getvalue]] [if [set ::privState(flagOBold)] {list bold} else list] [if [set ::privState(flagOItalic)] {list italic} else list]];set ::tmpIntState(outFont) [$f.fOutDef.sample cget -font]}]
			pack [label $f.fOutDef.sample -bd 2 -rel sunk -text {ABC Text 123} -height 2] -expand 1 -fill both -side bottom
			pack [ComboBox $f.fOutDef.fam -editable 0 -values [font families] -modifycmd $ecmdO] -side left
			pack [ComboBox $f.fOutDef.size -width 5 -values {4 6 8 10 12 14 16 18 20 22 24 26 28 36 48 72} -modifycmd $ecmdO] -side left
			pack [checkbutton $f.fOutDef.bold -indicatoron 0 -text B -font {{systemfixed} 9 bold} -padx 1 -variable ::privState(flagOBold) -command $ecmdO] -pady 1 -padx 1 -side left
			pack [checkbutton $f.fOutDef.italic -indicatoron 0 -text I -font {{systemfixed} 9 italic} -padx 4 -variable ::privState(flagOItalic) -command $ecmdO] -pady 1 -padx 1 -side left
			set font [lindex [.outText configure -font] 4]
			$f.fOutDef.fam setvalue @[lsearch -exact [lindex [$f.fOutDef.fam configure -values] 4] [lindex $font 0]]
			$f.fOutDef.size setvalue @[lsearch -exact [lindex [$f.fOutDef.size configure -values] 4] [lindex $font 1]]
			set ::privState(flagOBold) [expr [lsearch $font bold]>-1]
			set ::privState(flagOItalic) [expr [lsearch $font italic]>-1]
			eval $ecmdO

			pack [labelframe $f.fMnDef -text {Main Window Font}] -expand 0 -fill both
			set ecmdM [subst -nocommands {$f.fMnDef.sample configure -font [dlist [lindex [$f.fMnDef.fam cget -values] [$f.fMnDef.fam getvalue]] [lindex [$f.fMnDef.size cget -values] [$f.fMnDef.size getvalue]] [if [set ::privState(flagMBold)] {list bold} else list] [if [set ::privState(flagMItalic)] {list italic} else list]];set ::tmpIntState(font) [$f.fMnDef.sample cget -font]}]
			pack [label $f.fMnDef.sample -bd 2 -rel sunk -text {ABC Text 123} -height 2] -expand 1 -fill both -side bottom
			pack [ComboBox $f.fMnDef.fam -editable 0 -values [font families] -modifycmd $ecmdM] -side left
			pack [ComboBox $f.fMnDef.size -width 5 -values {4 6 8 10 12 14 16 18 20 22 24 26 28 36 48 72} -modifycmd $ecmdM] -side left
			pack [checkbutton $f.fMnDef.bold -indicatoron 0 -text B -font {{systemfixed} 9 bold} -padx 1 -variable ::privState(flagMBold) -command $ecmdM] -pady 1 -padx 1 -side left
			pack [checkbutton $f.fMnDef.italic -indicatoron 0 -text I -font {{systemfixed} 9 italic} -padx 4 -variable ::privState(flagMItalic) -command $ecmdM] -pady 1 -padx 1 -side left
			set font [lindex [.mainText configure -font] 4]
			$f.fMnDef.fam setvalue @[lsearch -exact [lindex [$f.fMnDef.fam configure -values] 4] [lindex $font 0]]
			$f.fMnDef.size setvalue @[lsearch -exact [lindex [$f.fMnDef.size configure -values] 4] [lindex $font 1]]
			set ::privState(flagMBold) [expr [lsearch $font bold]>-1]
			set ::privState(flagMItalic) [expr [lsearch $font italic]>-1]
			eval $ecmdM

#			set f [$w.f add 1]
#			$f con -bd 0 -rel groove

			set f [$w.f add 1]
			$f con -bd 0 -rel groove
			pack [labelframe $f.startup -text {On T-Sh-L Startup...}] -fill both
			pack [radiobutton $f.startup.rad1 -value New -variable tmpIntState(startMode) -text {Set Blank Project}] -anchor w -side left
			pack [radiobutton $f.startup.rad2 -value Recent -variable tmpIntState(startMode) -text {Open Recent Project}] -anchor w -side left
			pack [radiobutton $f.startup.rad3 -value Open -variable tmpIntState(startMode) -text {Display Open Dialog}] -anchor w -side left

			pack [entry $f.startup.expr -textvar tmpIntState(exprCmd) -width 50] -fill x 
	
			set f [$w.f add 2]
			$f con -bd 0 -rel groove
			pack [labelframe $f.helpSys -text {Help System}] -fill both -expand 1
			pack [labelframe $f.helpSys.chm -text {.CHM File Location Prefix}] -fill x 
			pack [entry $f.helpSys.chm.e -textvar tmpIntState(helpFile) -width 50] -fill x 
	
			$w.f compute_size
			$w.f raise 0
		
			pack [frame $w.sep -height 2] -expand 1 -fill both -pady 2
		}
	]
	if {$newPref==0} {
		array set ::intState [array get ::tmpIntState]
		.mainText con -font $::intState(font)
		.outText con -font $::intState(outFont)
		.mainText see [.mainText index insert]
	}
}

proc killSlave {} {
	catch {interp delete $::privState(slave)}
	unsetWatches
}
proc setSlave {{force 0}} {						;#build slave interpreter if none or corrupt
	if !$force&&![catch {$::privState(slave) eval {winfo id .}}] return
	killSlave
	set ::privState(slave) [interp create]
	$::privState(slave) eval {package require Tk}

	$::privState(slave) eval {rename puts TCLPuts}
	$::privState(slave) alias puts TSHLPuts
	$::privState(slave) alias exit killSlave
	setWatches
}

proc checkSaved {} {
	if !$::privState(saved) {
		set usrChoice [tk_messageBox -type yesnocancel -icon warning -default cancel -title "Save script?" -message "Script is been changed.\nSave now?"]
		if {$usrChoice eq {cancel}} {return 0}
		if {$usrChoice eq {yes}} {if ![prjSave] {return 0}}
	}
	return 1
}

proc prjNew {} {
	if ![checkSaved] {return 0}
	setSlave 1
	.mainText delete 0.0 end
	set ::privState(fileName) {}
	setTopName
	setSaved 1
	return 1
}

proc prjOpen {{tmpName {}}} {
	if {$tmpName eq {}} {
		set tmpName [tk_getOpenFile -defaultextension .tcl -parent . -title "Select a file to load from" -filetypes {{"Tcl Scripts" .tcl} {"All Files" *}} -initialfile $::privState(fileName)]
		if {$tmpName eq {}} {return 0}
	}
	if {[llength [glob -nocomplain $tmpName]]!=1} {return 0}

	if ![prjNew] {return 0}

	set ::privState(fileName) $tmpName
	set h [open $::privState(fileName)]
	.mainText insert insert [read $h]
	close $h
	setTopName
	setSaved 1
	recentAdd $::privState(fileName)
	cd [file dirname $::privState(fileName)]
	set ::intState(dir) [pwd]
	return 1
}
proc prjSave {{ask 0}} {
	set tempName $::privState(fileName)
#if need name
	if {$ask||($tempName eq {})} {
		set tempName [tk_getSaveFile -defaultextension .tcl -parent . -title "Select a file to save to" -filetypes {{"Tcl Scripts" .tcl} {"All Files" *}} -initialfile $::privState(fileName)]
		if {$tempName eq {}} {return 0}
	}
	set ::privState(fileName) $tempName
	set openErr [catch {set h [open $::privState(fileName) w]}]
	set putErr [catch {puts -nonewline $h [.mainText get 0.0 "end -1 chars"]; flush $h}]
	set closeErr [catch {close $h}]
	if $openErr||$putErr||$closeErr {tk_messageBox -icon error -message "Error while saving file.\nFile is not saved, accordingly.\n\nSee detailed info in next version." -title Oops...}
	setTopName
	setSaved 1
	recentAdd $::privState(fileName)
	set ::intState(dir) [pwd]
	return 1
}
proc autoSave {} {
	set openErr [catch {set h [open [subst $::privState(tempFiles)] w]}]
	set putErr [catch {puts -nonewline $h [.mainText get 0.0 "end -1 chars"]; flush $h}]
	set closeErr [catch {close $h}]
}
proc autoRestore {} {
	if {[file exists [subst $::privState(tempFiles)]]} {
		if {[tk_messageBox -message "Last session was hang.\n Autosave found for [clock format [file mtime [subst $::privState(tempFiles)]] -format {%d.%b, %H:%M:%S}]. \nRestore?" -title "Autorestore.." -icon error -type yesno]} {
			set h [open [subst $::privState(tempFiles)]]
			.mainText insert insert [read $h]
			close $h
			setSaved 0
			return 1
		}
	}
	return 0
}

proc ti {} {set ::__ki_timer [clock clicks]}
proc to {} {
	set new [expr ([clock clicks]-$::__ki_timer)]
	return "[expr $new/1000000/60]m, [expr ($new/1000000)%60]s, [expr $new%1000000]ms"
}

proc prjExeAcc {} {
	setSlave
	set outMsg {}
	ti
	set err [catch {set outMsg [$::privState(slave) eval $::privState(accumulator)]} outMsg]
	if $err {outPut "Error: $outMsg\n" evalerr} else {outPut "[to], Result: $outMsg\n" eval}
	set ::privState(accumulator) {}
}

proc prjExe {{from {}} {to {}}} {
	if {$from eq {}} return
	autoSave
	set af [expr {$::privState(accumulator)=={}}]
	append ::privState(accumulator) [.mainText get $from $to]
	if {$to=={insert lineend}} {append ::privState(accumulator) \n}
	set state [findBrace $::privState(accumulator)]
	set ::privState(accBraces) $::privState(braces)
	if {$state==-1} {outPut "Brace syntax error\n"; set ::privState(accumulator) {}; set ::privState(accBraces) {}; return}
	if {$state!=-3} {if {$af} {outPut "Code accumulated. Press ESC to flush.\n"}; return}
	prjExeAcc
}

proc prjExpr {{from {}} {to {}}} {
	if {$from eq {}} return
	setSlave
	set outMsg {}
	set inMsg [.mainText get $from $to]
	ti
	catch {set inMsg [$::privState(slave) eval "subst \{$inMsg\}"]} outMsg
	set err [catch {set outMsg [$::privState(slave) eval "$::intState(exprCmd) {$inMsg}"]} outMsg]
	if $err {outPut "Expr error: $outMsg\n" exprerr} else {if {$outMsg ne {}} {outPut "[to], Expr result: $outMsg\n" expr}}
}
proc setSaved {flag} {
	if $flag {
		set ::privState(saved) 1
		.mainText edit modified 0
		.statusLine.savedLab con -text S -bg green
		after 200 {.statusLine.savedLab con -bg green}
	} else {
		set ::privState(saved) 0
		.statusLine.savedLab con -text M -bg red
		after 200 {.statusLine.savedLab con -bg red}
	}
	after 100 {.statusLine.savedLab con -bg SystemButtonFace}
#	after 250 {.statusLine.savedLab con -bg SystemButtonFace}
}
proc setTopName {} {
	wm title . "$::privState(progName) - untitled"
	if {$::privState(fileName) eq {}} return
	wm title . "$::privState(progName) - $::privState(fileName)"
}
proc getIni {} {
	cd $::pwd
	array set ::intState [lindex [iniGetFile T-Sh-L.ini] 1]
	catch {cd $::intState(dir)}
}
proc setIni {} {
	cd $::pwd
	iniSetFile T-Sh-L.ini [list {T-Sh-L} [array get ::intState]]
	catch {cd $::intState(dir)}
}
proc setWrap {} {if {$::intState(wrap)==1} {.outText configure -wrap word} else {.outText configure -wrap none}}

proc prjInsert {x y} {
#set x 400
#set y 400
	destroy .menuNav
	menu .menuNav -tearoff 0

	destroy .menuNav.color
	menu .menuNav.color -tearoff 0
	.menuNav add cascade -label Color -menu .menuNav.color
	.menuNav.color add command -label custom -command {
		if {[set tmp [tk_chooseColor]]!={}} {
			.mainText insert insert $tmp
		}
	}
	
	.menuNav add separator

	.menuNav post $x $y
}

proc prjNavigate {x y} {
#set x 400
#set y 400
	destroy .menuNav
	menu .menuNav -tearoff 0

	set val [list proc [pickWord]]
	set regStr "\[\\n\\\{\]\[ \\t\]*${val}\[ \\t\]"
	set lookUp [regexp -inline -indices -all $regStr [.mainText get 1.0 end]]
	if {$lookUp ne {}} {
		foreach posV $lookUp {
			set posV2 [.mainText index "1.0+[expr [lindex $posV 1]+1] chars"]
			.menuNav add command -label $val -command ".mainText mark set insert $posV2; .mainText see $posV2"
		}
	}
	.menuNav add separator
	foreach val $::intState(navigateDic) {
		foreach {val ans} $val break
		set mName ".menuNav_$val"
		destroy $mName
		set regStr "\[\\n\\\{\]\[ \\t\]*${val}\[ \\t\]"
		set lookUp [regexp -inline -indices -all $regStr [.mainText get 1.0 end]]
		if {$lookUp ne {}} {
			menu $mName -tearoff 0
			foreach posV $lookUp {
				set posV2 [.mainText index "1.0+[expr [lindex $posV 1]+1] chars"]
				set nameV [regexp -inline [subst -noc -nob {^(?:[ \t]*[^( \t;)]*){$ans}}] [.mainText get $posV2 "$posV2 lineend"]]
				$mName add command -label [join "$val $nameV"] -command ".mainText mark set insert $posV2; .mainText see $posV2"
			}
			.menuNav add cascade -label $val -menu $mName
		}
	}
	.menuNav post $x $y
}
proc addBrace {} {
	set selRange [.mainText tag ranges sel]
	if {$selRange eq {}} {set selRange "[.mainText index insert] [.mainText index insert]"}
	set pre [.mainText get 1.0 [lindex $selRange 0]]
	set post [.mainText get [lindex $selRange 1] end]
	set noSel [expr [lindex $selRange 0]==[lindex $selRange 1]]
	set stat [findBrace $post 0 $pre $noSel]

	if {$stat==-1} {outPut "T-Sh-L Note: Brace Missing\n"; return}					;#check for boundaries
	if {$stat==-2} {outPut "T-Sh-L Note: Brace syntax is wrong\n"; return}			;#check for valid syntax
	if {$stat==-3} {outPut "T-Sh-L Note: No more braces\n"; return}					;#check for boundaries
	if {$stat==-4} {outPut "T-Sh-L Note: Braces mismatch\n"; return}	;#check for adequate braces

	.mainText tag add sel [.mainText index "1.0 + [lindex $stat 0] chars"] [.mainText index "[lindex $selRange 1] +[lindex $stat 1] chars +1 chars"]
}

proc findBrace {post {entireString {1}} {pre {}} {noSel {1}}} {
	set preI {}
	set tmp {}
	foreach val [regexp -inline -indices -all {[\\]*[\[\]()\{\}\"]} $pre] {
		if { !(([lindex $val 1]-[lindex $val 0])%2) } {
			lappend tmp [lindex $val 1]
		}
	}
	for {set i [expr [llength $tmp]-1]} {$i>=0} {set i [expr $i-1]} {lappend preI [lindex $tmp $i]}
	set postI {}
	foreach val [regexp -inline -indices -all {[\\]*[\[\]()\{\}\"]} $post] {
		if { !(([lindex $val 1]-[lindex $val 0])%2) } {
			lappend postI [lindex $val 1]
		}
	}
	lappend preI -1
	lappend postI -1								;# Here formed list of indices of braces
# Context is C_url, R_ound, Q_uote, B_ox
	set postOnly 0
	set maxContext {}
	set maxVal -1
	set b1 [string index $post 0]
	if {($noSel==1)&&(($b1 eq "\{")||($b1 eq {[})||($b1 eq {(}))&&!$entireString} {set postOnly 1}

	foreach maxVal $postI {
		switch [lindex $maxContext end] {
			{} {
				switch [string index $post $maxVal] {
					{[} {lappend maxContext B}
					"\{" {lappend maxContext C}
					{(} {lappend maxContext R}
					{"} {lappend maxContext Q}
					{]} {break}
					"\}" {break}
					{)} {break}
				}
			}
			{C} {
				switch [string index $post $maxVal] {
					{[} {}
					"\{" {lappend maxContext C}
					{(} {}
					{"} {}
					{]} {}
					"\}" {set maxContext [lrange $maxContext 0 end-1]}
					{)} {}
				}
			}
			{B} {
				switch [string index $post $maxVal] {
					{[} {lappend maxContext B}
					"\{" {lappend maxContext C}
					{(} {lappend maxContext R}
					{"} {lappend maxContext Q}
					{]} {set maxContext [lrange $maxContext 0 end-1]}
					"\}" {break}
					{)} {break}
				}
			}
			{R} {
				switch [string index $post $maxVal] {
					{[} {lappend maxContext B}
					"\{" {lappend maxContext C}
					{(} {lappend maxContext R}
					{"} {lappend maxContext Q}
					{]} {break}
					"\}" {break}
					{)} {set maxContext [lrange $maxContext 0 end-1]}
				}
			}
			{Q} {
				switch [string index $post $maxVal] {
					{[} {lappend maxContext B}
					"\{" {lappend maxContext C}
					{(} {lappend maxContext R}
					{"} {set maxContext [lrange $maxContext 0 end-1]}
					{]} {break}
					"\}" {break}
					{)} {break}
				}
			}
		}
		if {$postOnly&&($maxContext=={})} break
	}
set ::privState(braces) [regsub -all R $maxContext {(}]
set ::privState(braces) [regsub -all B $::privState(braces) {[}]
set ::privState(braces) [regsub -all C $::privState(braces) "\{"]
set ::privState(braces) [regsub -all Q $::privState(braces) {"}]
set ::privState(braces) [regsub -all { } $::privState(braces) {}]
	set minContext {}
	set minVal [string length $pre]
	if {!$postOnly} {
		set minVal -1
		foreach minVal $preI {
			switch [lindex $minContext end] {
				{} {
					switch [string index $pre $minVal] {
						{]} {lappend minContext B}
						"\}" {lappend minContext C}
						{)} {lappend minContext R}
						{"} {lappend minContext Q}
						{[} {break}
						"\{" {break}
						{(} {break}
					}
				}
				{C} {
					switch [string index $pre $minVal] {
						{]} {}
						"\}" {lappend minContext C}
						{)} {}
						{"} {}
						{[} {}
						"\{" {set minContext [lrange $minContext 0 end-1]}
						{(} {}
					}
				}
				{B} {
					switch [string index $pre $minVal] {
						{]} {lappend minContext B}
						"\}" {lappend minContext C}
						{)} {lappend minContext R}
						{"} {lappend minContext Q}
						{[} {set minContext [lrange $minContext 0 end-1]}
						"\{" {break}
						{(} {break}
					}
				}
				{R} {
					switch [string index $pre $minVal] {
						{]} {lappend minContext B}
						"\}" {lappend minContext C}
						{)} {lappend minContext R}
						{"} {lappend minContext Q}
						{[} {break}
						"\{" {break}
						{(} {set minContext [lrange $minContext 0 end-1]}
					}
				}
				{Q} {
					switch [string index $pre $minVal] {
						{]} {lappend minContext B}
						"\}" {lappend minContext C}
						{)} {lappend minContext R}
						{"} {set minContext [lrange $minContext 0 end-1]}
						{[} {break}
						"\{" {break}
						{(} {break}
					}
				}
			}
		}
	}
	if {$minVal==-1^$maxVal==-1} {return -1}					;#check for boundaries
	if {($minContext ne {})||($maxContext ne {})} {return -2}			;#check for valid syntax
	if {$minVal==-1&&$maxVal==-1} {return -3}					;#check for boundaries

	if !$postOnly {set b1 [string index $pre $minVal]}
	set b2 [string index $post $maxVal]
		
	if {(($b2 eq "\}")&&($b1 ne "\{"))||(($b2 eq {)})&&($b1 ne {(}))||(($b2 eq {]})&&($b1 ne {[}))} {return -4}	;#check for adequate braces

	return "$minVal $maxVal"
}

proc pickWord {} {
	set word [.mainText get "insert linestart" insert] 
	set i [string length $word]
	set word [join [list $word [.mainText get insert "insert lineend"]] {}]
	return [string range $word [string wordstart $word $i] [expr [string wordend $word $i]-1]]
}
proc HELP {} {
	set word [pickWord]
	if {$::intState(helpFile)=={}} {
		set hlpPath [regsub -all {\\} [exec cmd /c ftype [lindex [split [exec cmd /c assoc .tcl] =] 1]] /]
		set hlpPath [join [lrange [split [lindex [split $hlpPath =] 1 0] /] 0 end-2] /]
		set hlpPath [lindex [glob $hlpPath/doc/*.chm] 0]
	} else {
		set hlpPath [subst -nob [regsub -all {[%][^%]*[%]} $::intState(helpFile) {$::env([string range & 1 end-1])}]]
	}
	if {[info exists ::helpWords($word)]} {					;#! Substitute {\\%} in DICtionary with context word
#?		set ::privState(helph) [open "|hh \"${hlpPath}::/[regsub {\\%} $::helpWords($word) $word]\"" w]
		catch {winhelp . "${hlpPath}::/[regsub {\\%} $::helpWords($word) $word]"}
	} else {
		;#! do this for non-existetn words
	}
}
proc searchNew {{srOption 0}} {
	set sVal [modalWnd .search {Search Replace Cancel} $srOption {
		wm title $w {Search and Replace}
		pack [frame $w.searchFr] -fill x
			pack [entry $w.searchFr.entry -width 40 -textvariable ::intState(searchword)] -side right
			$w.searchFr.entry selection range 0 end
			after idle "focus $w.searchFr.entry"
			pack [label $w.searchFr.label -text {Search for:}] -side right
		pack [frame $w.replaceFr] -fill x
			pack [entry $w.replaceFr.entry -width 40 -textvariable ::intState(replaceword)] -side right
			pack [label $w.replaceFr.label -text {Replace with:}] -side right
#		pack [frame $w.linkFr] -fill x
#			pack [radiobutton $w.linkFr.checkRep -text {Replace} -indicator 1 -variable ::intState(searchLink) -val 0] -anchor e -side left -expand 1
#			pack [radiobutton $w.linkFr.checkLink -text {Link} -indicator 1 -variable ::intState(searchLink) -val 1] -anchor w -side left -expand 1
		pack [frame $w.splitFr1 -height 2 -rel sunk -bd 2] -fill x -pady 5
		pack [frame $w.optionsFr] -fill x
			pack [checkbutton $w.optionsFr.caseBut -text {Case sensitive} -variable ::intState(searchCase)] -anchor w -padx 100
			pack [checkbutton $w.optionsFr.backBut -text {Backward} -variable ::intState(searchBack)] -anchor w -padx 100
			pack [checkbutton $w.optionsFr.regExpBut -text {RegExp} -variable ::intState(searchRegExp)] -anchor w -padx 100
			pack [checkbutton $w.optionsFr.inSelBut -text {In Selection} -variable ::intState(searchInSel)] -anchor w -padx 100
		pack [frame $w.splitFr2 -height 2 -rel sunk -bd 2] -fill x -pady 5
	}]
	if {$sVal==0} {
		searchAgain
	}
	if {$sVal==1} {
		replaceAgain
	}
}

proc searchAgain {} {
	if {"$::intState(searchword)"!={}} {
		set ::privState(searchRange) {1.0 end}
		if {$::intState(searchInSel)} {set ::privState(searchRange) [.mainText tag ranges sel]}
		if {$::privState(searchRange)=={}} {set ::privState(searchRange) {1.0 end}}
		
		set sIdx [eval ".mainText search -count searchCnt [if  $::intState(searchBack) {list -backward} else list] [if  {!$::intState(searchCase)} {list -nocase} else list] [if  $::intState(searchRegExp) {list -regexp} else list] -- \{$::intState(searchword)\} [.mainText index insert] [if  $::intState(searchBack) {lindex $::privState(searchRange) 0} else {lindex $::privState(searchRange) 1}]"]

		if {$sIdx=={}} {
			set sVal [modalWnd .no {Search Cancel} 0 {
				wm title $w {Search Message:}
				pack [label $w.lab -text "Nothing found..\n\nTry from begin?" -font {{} 10} -just left] -padx 20 -pady 20
			}]
			if {$sVal==0} {
				if  {$::intState(searchBack)} {catch {.mainText mark set insert [lindex $::privState(searchRange) 1]}}
				if  {!$::intState(searchBack)} {catch {.mainText mark set insert [lindex $::privState(searchRange) 0]}}
				return [searchAgain]
			}
			return 0
		}
		.mainText tag remove altSel 0.0 end

		.mainText tag add altSel $sIdx "$sIdx+$searchCnt chars"
		if  {!$::intState(searchBack)} {
			.mainText mark set insert "$sIdx+$searchCnt chars"
		} else {
			.mainText mark set insert $sIdx
		}
		.mainText see $sIdx
		focus .mainText
	}
	return 1
}

proc replaceAgain {{rVal -1}} {
	if {![searchAgain]} return
	if {$rVal==-1} {
		set rVal [modalWnd .query {Replace {Replace All} {Replace and stop} Skip Cancel} 0 {
			wm title $w {Replace Message:}
			pack [label $w.lab -text "Confirm replace.." -font {{} 10} -just left] -padx 20 -pady 20
		}]
	}
	if {$rVal==0||$rVal==1||$rVal==2} {
		set searchRange [.mainText tag ranges altSel]
		.mainText delete [lindex $searchRange 0] [lindex $searchRange 1]
		.mainText insert [lindex $searchRange 0] $::intState(replaceword)
	}
	if {$rVal==0||$rVal==3} {after idle replaceAgain}
#! fix recursive replace
	if {$rVal==1} {after idle replaceAgain 1}
}

proc recentAdd {nam {andArray 1}} {
	if {$andArray} {
		set idx [lsearch -exact $::intState(recentFiles) $nam]
		set ms [llength $::intState(recentFiles)]
		if {$idx!=-1} {
			.menuMain.menuRecent  delete [expr $ms-$idx]
			set ::intState(recentFiles) [lreplace $::intState(recentFiles) $idx $idx]
		} else {
			if {$ms>10} {
				for {set i $ms} {$i>10} {incr i -1} {.menuMain.menuRecent delete $i}
				set ::intState(recentFiles) [lreplace $::intState(recentFiles) 0 end-10]
			}
		}
		lappend ::intState(recentFiles) $nam
	}
	.menuMain.menuRecent insert 0 command -label $nam -command [list prjOpen $nam]
}

proc prjIni fn {
	wm withdraw .

	catch {load winhelp/winhelp.dll}
	set h [open winhelp/tclhelp.dic]
	array set ::helpWords [read $h]
	close $h

	getIni

	makeUpDraw
	makeUpMenu
	makeUpBind

	set fn [regsub -all {\\} $fn /]
	foreach val $::intState(recentFiles) {recentAdd $val 0}
	if $::intState(hangFlag) {
		set ::privState(fileName) {}
		set ::intState(hangFlag) [autoRestore]
	}
	if {!$::intState(hangFlag)} {
		if {$fn=={}} {
			if {($::intState(startMode)=={Recent}) && ($val ne {})} {prjOpen $val}
			if {$::intState(startMode)=={Open}} {
				update
				event generate . <<eOpen_Doc>>
			}
		} else {prjOpen $fn}
	}
	set ::intState(hangFlag) 1
	setIni

	setTopName
	if {$::intState(geom) eq {}} {wm geometry . 600x400} else {wm geometry . $::intState(geom)}
	if {$::intState(font) ne {}} {.mainText configure -font $::intState(font)}
	if {$::intState(outFont) ne {}} {.outText configure -font $::intState(outFont)}

	setWrap
	vSepMot 1 $::intState(separator)
	.mainText edit modified 0
	.mainText mark set insert "$::intState(posX).$::intState(posY)"
	bind .mainText <<Modified>> {
		if [.mainText edit modified] {setSaved 0}
	}
	wm protocol . WM_DELETE_WINDOW {event generate . <<eExit>>}
	focus .mainText

	wm deiconify .
	after idle { after 1 {
		.mainText xview moveto $::intState(hScroll)
		.mainText yview moveto $::intState(vScroll)
		.mainText see insert
	}}
}
proc globalUpdates {} {
	bind Text <Key-Right> {if {[%W tag ranges sel] eq {}} {tk::TextSetCursor %W insert+1c} else {tk::TextSetCursor %W [lindex [%W tag ranges sel] 1]}}
	bind Text <Key-Left> {if {[%W tag ranges sel] eq {}} {tk::TextSetCursor %W insert-1c} else {tk::TextSetCursor %W [lindex [%W tag ranges sel] 0]}}
	bind Text <Key-Down> {if {[%W tag ranges sel] eq {}} {tk::TextSetCursor %W [tk::TextUpDownLine %W 1]} else {tk::TextSetCursor %W [lindex [%W tag ranges sel] 1]}}
	bind Text <Key-Up> {if {[%W tag ranges sel] eq {}} {tk::TextSetCursor %W [tk::TextUpDownLine %W -1]} else {tk::TextSetCursor %W [lindex [%W tag ranges sel] 0]}}
	bind Text <Control-a> {}
	bind Button <Return> {::tk::ButtonInvoke %W}
	. configure -menu [menu .x]
	rename ::tk::TearOffMenu ::tk::TearOffMenu_old
	proc ::tk::TearOffMenu {w {x 0} {y 0}} {wm attributes [::tk::TearOffMenu_old $w $x $y] -toolwindow 1}
}
#############################
proc outPut {what {how {}}} {
	.outText con -state normal
		.outText insert end $what $how
	.outText con -state disabled
	.outText see end
}
proc TSHLPuts args {
	set len [llength $args]
	foreach {arg1 arg2 arg3} $args break

	if {$len == 1} {
		outPut "$arg1\n" stdout
	} elseif {$len == 2} {
		if {![string compare $arg1 -nonewline]} {
			outPut $arg2 stdout
		} elseif {![string compare $arg1 stdout] || ![string compare $arg1 stderr]} {
			outPut "$arg2\n" $arg1
		} else {
			set len 0
		}
	} elseif {$len == 3} {
		if {![string compare $arg1 -nonewline] && (![string compare $arg2 stdout] || ![string compare $arg2 stderr])} {
			outPut $arg3 $arg2
		} elseif {(![string compare $arg1 stdout] || ![string compare $arg1 stderr]) && ![string compare $arg3 nonewline]} {
			outPut $arg2 $arg1
		} else {
			set len 0
		}
	} else {
		set len 0
	}
	if {$len == 0} {
		global errorCode errorInfo
		if {[catch {$::privState(slave) eval "TCLPuts $args"} msg]} {
			regsub TCLPuts $msg puts msg
			regsub -all TCLPuts $errorInfo puts errorInfo
			return -code error $msg
		}
		return $msg
	}
	if {$len} {
		update idletasks
	}
}



### test of extension#############!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#.watchTop.frWatchList.alVar con -width 0

proc registerWatch {} {
	namespace eval watchStr {
		set watchSlider 0.5
		set newEntry {}
		array set watchVal {}
	}
	toplevelHid .watchTop
	wm title .watchTop "Watch"
	pack [frame .watchTop.frWatchList] -fill both -expand 0
		pack [frame .watchTop.frWatchList.tit] -fill both
			pack [label .watchTop.frWatchList.tit.var -bd 2 -rel raise -text "Name"] -side left -fill x -expand 1
			pack [label .watchTop.frWatchList.tit.val -bd 2 -rel raise -text {Value}] -side left -fill x -expand 1

	pack [frame .watchTop.frWatchAdd] -fill x -expand 0
		pack [entry .watchTop.frWatchAdd.var -textvar ::watchStr::newEntry -validate focusout -vcmd {return [addWatch]} -rel groov] -side left -expand 1 -fill x
		pack [entry .watchTop.frWatchAdd.val -state disabled -rel flat] -side left -expand 1 -fill x
		bind .watchTop.frWatchAdd.var <Return> addWatch
	wm protocol .watchTop WM_DELETE_WINDOW {wm withdraw .watchTop}
}

proc addWatch {{wName {}}} {
	regsub :{2,} $wName {} wName

	if {$wName=={}} {set wName $::watchStr::newEntry}
	if {$wName=={}} {return 1}
	if [info exist ::watchStr::watchVal($wName)] {set ::watchStr::newEntry {}; return 0}
	.watchTop.frWatchAdd.var con -validate none

	pack [frame .watchTop.frWatchList.watch$wName] -fill x -expand 1
		menu .watchTop.frWatchList.watch$wName.menu -tearoff 0
			.watchTop.frWatchList.watch$wName.menu add command -label {Unset Variable} -command "unsetWatch $wName"
			.watchTop.frWatchList.watch$wName.menu add command -label {Delete Watch} -command "delWatch $wName"
		pack [frame .watchTop.frWatchList.watch$wName.var -bd 0] -side left -fill x -expand 1
			pack [label .watchTop.frWatchList.watch$wName.var.var -text $wName -rel raise -cursor arrow -width 20] -side left -fill x -expand 1
				bind .watchTop.frWatchList.watch$wName.var.var <3> [subst -noc {.watchTop.frWatchList.watch$wName.menu post  [winfo rootx %W] [expr [winfo rooty %W]+[winfo height %W]]}]
		pack [frame .watchTop.frWatchList.watch$wName.val -bd 0] -side left -fill x -expand 1
			pack [entry .watchTop.frWatchList.watch$wName.val.val -textvar ::watchStr::watchVal($wName) -validate none -vcmd [subst -noc {return [setWatch $wName]}]] -side left -fill x -expand 1
							bind .watchTop.frWatchList.watch$wName.val.val <Return> "setWatch $wName"
	updateWatchVariable $wName {} unset					;#Set update from Slave
	if {![interp exist $::privState(slave)]} {
		.watchTop.frWatchList.watch$wName.val.val con -state disabled
		.watchTop.frWatchList.watch$wName.menu entryconf 0 -state disabled
	}

	set ::watchStr::newEntry {}
	.watchTop.frWatchAdd.var con -validate focusout
	return 1
}
proc delWatch {uID} {
	destroy .watchTop.frWatchList.watch$uID
	if {[interp exist $::privState(slave)]} {
		$::privState(slave) eval "trace remove variable $uID {write unset} ::T_SH_L::updateWatchVariable"
	}
	unset ::watchStr::watchVal($uID)
}
proc updateWatchVariable {a1 a2 a3} {
	regsub :{2,} $a1 {} a1
	if {$a2!={}} {set a1 ${a1}($a2)}
	set w .watchTop.frWatchList.watch$a1.val.val
	if ![winfo exists $w] {
		return
	}

	$w con -validate none
	if {$a3=={unset}} {
		if {[interp exist $::privState(slave)]} {
			$::privState(slave) eval "trace remove variable $a1 {write unset} ::T_SH_L::updateWatchVariable"
			$::privState(slave) eval "trace add variable $a1 {write unset} ::T_SH_L::updateWatchVariable"
		}
	}
#todo: setting array from udefined is no handled
	if {[interp exist $::privState(slave)]} {
		if [$::privState(slave) eval "info exist $a1"] {
			if [$::privState(slave) eval "array exist $a1"] {
				$w con -font [concat [lrange [$w cget -font] 0 0] 10 italic]
				set ::watchStr::watchVal($a1) {Array}
			} else {
				$w con -font [concat [lrange [$w cget -font] 0 0] 10 roman]
				set ::watchStr::watchVal($a1) [$::privState(slave) eval "set $a1"]
			}
		} else {
			$w con -font [concat [lrange [$w cget -font] 0 0] 10 italic]
			set ::watchStr::watchVal($a1) {Undefined}
		}
	}
	after idle "$w con -validate focusout"
}
proc setWatches {} {
	$::privState(slave) alias ::T_SH_L::updateWatchVariable updateWatchVariable
	foreach var [array names ::watchStr::watchVal] {
		.watchTop.frWatchList.watch$var.val.val con -state normal
		.watchTop.frWatchList.watch$var.menu entryconf 0 -state normal
		updateWatchVariable $var {} unset
	}
}
proc unsetWatches {} {
	foreach var [array names ::watchStr::watchVal] {
		updateWatchVariable $var {} unset
		.watchTop.frWatchList.watch$var.val.val con -state disabled
		.watchTop.frWatchList.watch$var.menu entryconf 0 -state disabled		
	}
}
proc setWatch {wName} {
	$::privState(slave) eval "set $wName [set ::watchStr::watchVal($wName)]"
	return 1
}
proc unsetWatch {wName} {
	focus .watchTop.frWatchAdd.var
	$::privState(slave) eval "catch {unset $wName}"
}


##END OF PROCS############################################################################################

globalUpdates

prjIni [lindex $argv 0]

#register extension
registerWatch

#fixUp
setSlave 1

#garbage vvvvvvvvv

#bind . <F12> {console show}


