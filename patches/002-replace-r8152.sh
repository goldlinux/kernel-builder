#!/bin/bash

SRCFILE="$(dirname "$(readlink -f "$0")")/r8152.c"
SRCHEADER="$(dirname "$(readlink -f "$0")")/compatibility.h"

headerdest=$DIR/$DEST/drivers/net/usb/compatibility.h

ACTION=""

show_help() {
  echo "No action provided. Use $0 -u (uninstall) or $0 -i (install)"
  exit 1
}

overwrite_file() {
  local src=$1
  local dest=$2
  if [ -e ${dest}.orig ]; then
    echo "** ${dest}.orig already exists, not overwriting"
  else
    mv ${dest} ${dest}.orig
    cp $src $dest
  fi
}

restore_file() {
  local dest=$1
  if [ -e ${dest}.orig ]; then
    rm -f ${dest}
    mv ${dest}.orig ${dest}
  fi
}

while getopts "iu" opt; do
  case ${opt} in
    \? )
      show_help
      ;;
    i )
      ACTION="install"
      ;;
    u )
      ACTION="uninstall"
      ;;
  esac
done

if [ ! "$ACTION" ]; then
  show_help
fi

if [ "$ACTION" == "install" ]; then
  overwrite_file $SRCFILE $DIR/$DEST/drivers/net/usb/r8152.c
  [ ! -e $headerdest ]; cp $SRCHEADER $headerdest
fi

if [ "$ACTION" == "uninstall" ]; then
  restore_file $DIR/$DEST/drivers/net/usb/r8152.c
  rm -f $headerdest
fi


