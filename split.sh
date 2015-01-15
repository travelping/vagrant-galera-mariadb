#!/bin/bash

while true
do
 sudo tc qdisc add dev eth1 root netem loss 100%
 sleep $1
 sudo tc qdisc del dev eth1 root
 sleep $2
 echo "run"
done
