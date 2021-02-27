#!/bin/sh

nohup sudo Xvfb :0 -ac -screen 0 1280x1024x24 > ~/X.log 2>&1 &

export DISPLAY=:0

"$@"
