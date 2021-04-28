#!/bin/bash

source config.sh

DATA_PATH=$(pwd)/bulk-sync-processed-data
echo $DATA_PATH

mkdir -p $DATA_PATH
rm -rf $DATA_PATH/*

for m in ${MODE[@]}; do
    for qthread in ${NUM_QTHREADS[@]}; do
        for point in ${NUM_POINTS[@]}; do
            for c in ${NUM_CENTERS[@]}; do
                new_c=$c
                # if [[ ( $c -lt 10  ) ]]; then
                #     new_c=0$c
                # fi
                for thread in ${NUM_PARALLEL_KERNEL[@]}; do
                    new_thread=$thread
                    if [[ ( $thread -lt 10 ) ]]; then
                        new_thread=0$thread
                    fi
                    # Use cmake -DRAFT_ROOT=/benchmarks/VirtualLink/RaftLib/ -DVL_ROOT=/benchmarks/VirtualLink/libvl/ ../
                    actual_num_points=$((thread*point))
                    point_format=${actual_num_points}
                    if [[ ( $point_format -lt 9999 ) ]]; then
                        point_format=00${point_format}
                    elif [[ ( $point_format -lt 99999 ) ]]; then
                        point_format=0${point_format}
                    fi
                    container_name=$BENCHNAME-${m}q${qthread}-${actual_num_points}-$c-$thread
                    stat_file_name=$BENCHNAME-${m}q${qthread}-${point_format}-$new_c-$new_thread
                    cp $(pwd)/bulk-sync-data/${container_name}/stats.txt $DATA_PATH/${stat_file_name}.data
                done
            done
        done
    done
done
