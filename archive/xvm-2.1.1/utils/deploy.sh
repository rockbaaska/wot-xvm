#!/bin/sh

GAME_VER="0.7.2"
FILES="battle.swf battleloading.swf PlayersPanel.swf StatisticForm.swf VehicleMarkersManager.swf XVM.xvmconf OTMData.xml"

cd $(dirname $(realpath $(cygpath --unix $0)))

[ "$WOT_DIRECTORY" = "" ] && WOT_DIRECTORY=/cygdrive/d/home/games/WoT
SWF_DIR="$WOT_DIRECTORY/res_mods/$GAME_VER/gui/flash"

copy_file()
{
  [ -f "$SWF_DIR/$1" ] && rm -f "$SWF_DIR/$1"
  [ -f "../bin/$1" ] && {
    echo "=> $1"
    cp ../bin/$1 "$SWF_DIR/$1"
  }
}

for file in $FILES; do
  copy_file $file
done