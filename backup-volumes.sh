#!/bin/bash

set -x
set -u

ts=`date "+%d-%m-%y-%H-%M"`

destdir="/backup/$ts"
mkdir -p $destdir

tar cvf "$destdir/dev-home.tar" /home/dev/
zip -r9 -X "$destdir/dev-home.zip" /home/dev/