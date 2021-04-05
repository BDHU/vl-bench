BENCHNAME=bulk-sync
MODE=(s d v)
NUM_POINTS=(1024)
NUM_QTHREADS=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16)
NUM_PARALLEL_KERNEL=(1 2 4 8 16 32 64)
NUM_CENTERS=(3)

mkdir ./bulk-sync-boot
cd ./bulk-sync-boot
rm -rf *

for m in ${MODE[@]}; do
    for qthread in ${NUM_QTHREADS[@]}; do
        for point in ${NUM_POINTS[@]}; do
            for c in ${NUM_CENTERS[@]}; do
                for thread in ${NUM_PARALLEL_KERNEL[@]}; do
                    file_name=$BENCHNAME-${m}q$qthread-$point-$c-$thread.sh
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
