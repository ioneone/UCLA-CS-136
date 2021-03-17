#!/bin/bash

# Usage: ./price.sh [symbol] [new]
# Example: ./price.sh FZCO 10

symbol=$1
new=$2
hash=$(echo -n $symbol$new | md5sum | head -c 32)

curl -s -o /dev/null "http://10.1.1.3/cgi-bin/stock.cgi?symbol=$symbol&new=$new&hash=$hash"