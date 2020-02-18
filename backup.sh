#!/bin/bash
export BORG_PASSPHRASE="vagrant"
borg create --list -v --stats --compression zlib,5 borg@192.168.13.11:/home/borg/backup::"etc-{now:%Y-%m-%d_%H:%M:%S}" /etc
