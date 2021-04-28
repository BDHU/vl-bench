#!/bin/bash

source config.sh

mkdir ./bulk-sync-boot
cd ./bulk-sync-boot
rm -rf *

for m in ${MODE[@]}; do
    for qthread in ${NUM_QTHREADS[@]}; do
        for point in ${NUM_POINTS[@]}; do
            for c in ${NUM_CENTERS[@]}; do
                for thread in ${NUM_PARALLEL_KERNEL[@]}; do
                    actual_num_points=$((thread*point))
                    file_name=$BENCHNAME-${m}q$qthread-${actual_num_points}-$c-$thread.rcS
                    echo $file_name
                    touch $file_name
                    echo "#!/bin/sh" >> $file_name
                    echo "cd /benchmarks/VirtualLink" >> $file_name
                    echo "/sbin/m5 resetstats " >> $file_name
                    echo "./bulk-sync -${m} -q${qthread} ${point} ${c} ${thread}" >> $file_name
                    echo "/sbin/m5 exit" >> $file_name
                done
            done
        done
    done
done
