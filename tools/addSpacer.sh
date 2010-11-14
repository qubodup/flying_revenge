#!/bin/bash

if [ -z $2 ] ; then
	echo -e "Give following parameters: FILE WIDTHxHEIGHT. Example:\n ./addSpacer.sh spritesheet.png 16x24"
else

	# temp file names
	TEMPNAME="temp"

	# split
	convert "$1" -crop $2 "$TEMPNAME.png"

	# add border/frame/extent
	for i in $TEMPNAME*; do convert "$i" -splice 1x0 "$i"; done

	# montage
	files=$(ls $TEMPNAME*.png | sort -t '-' -n -k 2 | tr '\n' ' ')
	montage $files -tile x1 -background none -geometry $WIDTHx$HEIGHT+0+0 "${1%.png}-padding.png"

	# cleanup
	rm "$TEMPNAME"*
fi
