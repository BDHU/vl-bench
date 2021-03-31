#!/bin/bash


# Use cmake -DRAFT_ROOT=/benchmarks/VirtualLink/RaftLib/ -DVL_ROOT=/benchmarks/VirtualLink/libvl/ ../
docker run \
    -v ~/boost_1_63_0:/boost_1_63_0 \
    -v ~/vl-bench:/vl-bench \
    -d --privileged --name gem5 jonbea01/ubuntu-x86-gem5:16Mar2021CDT1726 \
    tail -f /dev/null

docker exec -it gem5 bash -c 'cd /simruns/dist/disks \
&& mkdir mnt1 \
&& mount -o loop,offset=65536,sizelimit=4294967296 cmake-ubuntu18.10-aarch64.1.img mnt1/ \
&& mount -t proc none mnt1/proc \
&& mount -o bind /dev mnt1/dev \
&& mount -o bind /sys mnt1/sys \
&& cd / && mkdir /simruns/dist/disks/mnt1/benchmarks/VirtualLink/vl-bench \
&& mount --bind /vl-bench /simruns/dist/disks/mnt1/benchmarks/VirtualLink/vl-bench \
&& mount --bind /boost_1_63_0 /simruns/dist/disks/mnt1/benchmarks/VirtualLink/boost_1_63_0 \
&& mount --bind /gem5 /simruns/dist/disks/mnt1/benchmarks/VirtualLink/near-data-sim'
docker exec -it gem5 bash
