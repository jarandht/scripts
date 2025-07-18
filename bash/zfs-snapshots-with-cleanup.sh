#!/bin/bash
POOL="pool"
DATASET="dataset"
KEEP="30" # Keep for 30 days

zfs snapshot -r $POOL/$DATASET@auto_$(date +%d-%m-%Y_%H-%M)
zfs list -t snapshot -o name | grep $POOL/$DATASET@auto | tac | tail -n +$KEEP | xargs -I {} sudo zfs destroy -r {}
