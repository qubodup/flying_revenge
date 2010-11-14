#!/bin/bash
# temp file names
TEMPNAME="temp"
# split
convert "$1" -crop 16x16 "$TEMPNAME.png"
# add border/frame/extent
for i in $TEMPNAME*; do convert "$i" -background LimeGreen -compose Copy -gravity west -splice 1x0 "$i"; done
# montage
files=$(ls $TEMPNAME*.png | sort -t '-' -n -k 2 | tr '\n' ' ')
montage $files -tile x1 -background none -geometry +0+0 "${1%.png}-padding.png"
# cleanup
rm "$TEMPNAME"*
