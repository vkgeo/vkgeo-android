#!/bin/sh

find ../resources -name '*.png' -exec mogrify -verbose {} \;
