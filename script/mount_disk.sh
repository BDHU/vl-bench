#!/bin/bash

cd /simruns/dist/disks
mkdir mnt1
mount -o loop,offset=65536,sizelimit=4294967296 cmake-ubuntu18.10-aarch64.1.img mnt1/
mount -t proc none mnt1/proc
mount -o bind /dev mnt1/dev
mount -o bind /sys mnt1/sys

cd /
mount --bind /vl-bench /simruns/dist/disks/mnt1/benchmarks/VirtualLink/vl-bench
