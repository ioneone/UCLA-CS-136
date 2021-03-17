#!/bin/bash

cd /usr/lib/cgi-bin
sudo patch < /root/part2/fixed.patch
sudo chmod u-s memo.cgi