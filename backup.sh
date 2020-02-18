#!/bin/bash
export BORG_PASSPHRAS="vagrant"
borg create --list -v --stats borg@192.168.13.11:/home/borg/backup::"etc-{now:%Y-%m-%d_%H:%M:%S}" /etc
