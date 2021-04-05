#!/bin/bash

source config.sh

BOOTSCRIPT_DIR=$(pwd)/bulk-sync-boot
echo $BOOTSCRIPT_DIR

for m in ${MODE[@]}; do
    for qthread in ${NUM_QTHREADS[@]}; do
        for point in ${NUM_POINTS[@]}; do
            for c in ${NUM_CENTERS[@]}; do
                for thread in ${NUM_PARALLEL_KERNEL[@]}; do
                    # Use cmake -DRAFT_ROOT=/benchmarks/VirtualLink/RaftLib/ -DVL_ROOT=/benchmarks/VirtualLink/libvl/ ../
                    container_name=$BENCHNAME-${m}q${qthread}-$point-$c-$thread
                    docker kill $container_name
                    docker rm $container_name
                done
            done
        done
    done
done
