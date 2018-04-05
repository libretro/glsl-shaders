#!/bin/bash

#######################################
# Variables                           #
#######################################

SCRIPT_DIR=$(dirname $(which $0))

SRC_DIR="$SCRIPT_DIR/png"
OUT_BASE_DIR="$SCRIPT_DIR/../png"
OUT_DIR=

SRC_IMG=
TMP_IMG="$SCRIPT_DIR/tmp.png"
OUT_IMAGE=

IMG_NAME=

SRC_WIDTH=
SRC_HEIGHT=

NUM_TILES=
NUM_TILES_X=
NUM_TILES_Y=

# Resolution-dependent stuff...
TEXTURE_SIZES[0]="2048"
TEXTURE_SIZES[1]="4096"
TEXTURE_SIZE=

OUT_SUB_DIRS[0]="2k"
OUT_SUB_DIRS[1]="4k"

#######################################
# Generate BG textures                #
#######################################

cd "$SCRIPT_DIR"

for SRC_IMG in "$SRC_DIR"/*.png
do
	IMG_NAME="$(basename "$SRC_IMG")"
	
	echo "-> $IMG_NAME"
	
	# Get image dimensions
	SRC_WIDTH=$(identify -format '%w' "$SRC_IMG")
	SRC_HEIGHT=$(identify -format '%h' "$SRC_IMG")
	
	# Loop over output texture sizes
	for INDEX in $(seq 0 $((${#TEXTURE_SIZES[@]} - 1)))
	do
		TEXTURE_SIZE="${TEXTURE_SIZES[INDEX]}"
		OUT_DIR="$OUT_BASE_DIR/${OUT_SUB_DIRS[INDEX]}"
		OUT_IMAGE="$OUT_DIR/$IMG_NAME"
		
		echo "   - $TEXTURE_SIZE x $TEXTURE_SIZE"
		
		# Make output directory, if required
		mkdir -p "$OUT_DIR"
		
		# Get number of tiles required...
		NUM_TILES_X=$(echo "($TEXTURE_SIZE + $SRC_WIDTH - 1) / $SRC_WIDTH" | bc)
		NUM_TILES_Y=$(echo "($TEXTURE_SIZE + $SRC_HEIGHT - 1) / $SRC_HEIGHT" | bc)
		NUM_TILES=$(echo "$NUM_TILES_X * $NUM_TILES_Y" | bc)

		# Create 'montage'
		# (ugh... this is ugly...)
		montage $(printf "${SRC_IMG}%.0s " $(eval echo "{1..$NUM_TILES}")) -geometry ${SRC_WIDTH}x${SRC_HEIGHT} -tile ${NUM_TILES_X}x${NUM_TILES_Y} "$TMP_IMG"
		
		# Crop to required texture dimensions
		convert "$TMP_IMG" -crop ${TEXTURE_SIZE}x${TEXTURE_SIZE}+0+0 "$TMP_IMG"
		
		# All the src images are too bright, so hardcode some brightness/contrast adjustment...
		convert "$TMP_IMG" -brightness-contrast -30x25 "$TMP_IMG"
		
		# Convert to greyscale
		convert "$TMP_IMG" -colorspace Gray "$OUT_IMAGE"
		
		# Clean up...
		rm -f "$TMP_IMG"
		
	done
	
done
