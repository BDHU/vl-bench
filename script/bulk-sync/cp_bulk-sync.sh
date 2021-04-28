#!/bin/bash

source config.sh

BOOTSCRIPT_DIR=$(pwd)/bulk-sync-data
echo $BOOTSCRIPT_DIR

mkdir -p $BOOTSCRIPT_DIR

for m in ${MODE[@]}; do
    for qthread in ${NUM_QTHREADS[@]}; do
        for point in ${NUM_POINTS[@]}; do
            for c in ${NUM_CENTERS[@]}; do
                for thread in ${NUM_PARALLEL_KERNEL[@]}; do
                    # Use cmake -DRAFT_ROOT=/benchmarks/VirtualLink/RaftLib/ -DVL_ROOT=/benchmarks/VirtualLink/libvl/ ../
                    actual_points=$((thread*point))
                    container_name=$BENCHNAME-${m}q${qthread}-${actual_points}-$c-$thread

                    docker cp ${container_name}:/data_store/m5_outputs/$container_name $BOOTSCRIPT_DIR
                done
            done
        done
    done
done
