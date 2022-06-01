#!/bin/sh

echo "Installing Xcode Themes"
set -x
DESTDIR=~/Library/Developer/Xcode/UserData/FontAndColorThemes/
mkdir -p $DESTDIR
cp *.xccolortheme $DESTDIR/