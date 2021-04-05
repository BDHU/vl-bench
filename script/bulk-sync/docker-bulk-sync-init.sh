#!/bin/bash

BENCHNAME=bulk-sync
MODE=(v)
NUM_POINTS=(1)
NUM_QTHREADS=(1)
NUM_PARALLEL_KERNEL=(1)
NUM_CENTERS=(1)

BOOTSCRIPT_DIR=$(pwd)/bulk-sync-boot
echo $BOOTSCRIPT_DIR

for m in ${MODE[@]}; do
    for qthread in ${NUM_QTHREADS[@]}; do
        for point in ${NUM_POINTS[@]}; do
            for c in ${NUM_CENTERS[@]}; do
                for thread in ${NUM_PARALLEL_KERNEL[@]}; do
                    # Use cmake -DRAFT_ROOT=/benchmarks/VirtualLink/RaftLib/ -DVL_ROOT=/benchmarks/VirtualLink/libvl/ ../
                    container_name=$BENCHNAME-${m}q${qthread}-$point-$c-$thread
                    docker run \
                        --env SCRIPT_LABEL=$container_name \
                        -v ~/boost_1_63_0:/boost_1_63_0 \
                        -v ~/vl-bench:/vl-bench \
                        -d --privileged --name $container_name ed:gem5-bulk-sync \
                        tail -f /dev/null

                    # docker exec -it $container_name bash -c 'cd /simruns/dist/disks \
                    # && cd / && mkdir /simruns/dist/disks/mnt1/benchmarks/VirtualLink/vl-bench \
                    # && mount --bind /vl-bench /simruns/dist/disks/mnt1/benchmarks/VirtualLink/vl-bench \
                    # && mount --bind /boost_1_63_0 /simruns/dist/disks/mnt1/benchmarks/VirtualLink/boost_1_63_0 \
                    # && mount --bind /gem5 /simruns/dist/disks/mnt1/benchmarks/VirtualLink/near-data-sim'
                    # cp run script to container
                    
                    docker cp $(pwd)/run-bulk-sync.sh ${container_name}:/simruns/VirtualLink/run-bulk-sync.sh
                    # docker exec -it ${container_name} bash -c 'cd /simruns/VirtualLink && mkdir -p ${container_name}'
                    docker exec  ${container_name} mkdir -p /simruns/VirtualLink/m5_outputs/$container_name
                    docker cp ${BOOTSCRIPT_DIR}/${container_name}.rcS ${container_name}:/simruns/VirtualLink/m5_outputs/${container_name}/${container_name}.rcS
                    docker exec  $container_name bash -c 'cd /simruns/VirtualLink \
                    && ./run-bulk-sync.sh ${SCRIPT_LABEL}'
                done
            done
        done
    done
done
