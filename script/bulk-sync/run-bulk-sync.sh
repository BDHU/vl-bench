#!/bin/bash

BASE_PATH=/simruns

export M5_PATH=${BASE_PATH}/dist
M5_PATH=${BASE_PATH}/dist

GEM5_PATH=/gem5

WORK_PATH=/simruns/VirtualLink

RESULTS_PATH=/data_store/

cd ${WORK_PATH}

BENCHNAME=$1

mkdir -p ${RESULTS_PATH}/m5_outputs/${BENCHNAME}
mkdir -p ${WORK_PATH}/m5_outputs/${BENCHNAME}

#cp ../scripts/${SCRIPTLABEL} ${RESULTS_PATH}/m5_outputs/${TIMESTAMPE}
#cp ../scripts/${SCRIPTLABEL} ${WORK_PATH}/m5_outputs/${TIMESTAMPE}
# uncomment the following command to run test simulation
${GEM5_PATH}/build/ARM/gem5${2}.opt \
    --listener-mode=off \
    --debug-flags=VirtualLinkMonitor \
    -d ${RESULTS_PATH}/m5_outputs/${BENCHNAME} \
    ${GEM5_PATH}/configs/example/arm/fs_bigLITTLE_vl.py \
    --restore-from ${WORK_PATH}/m5_outputs/ckpt/ \
    --cpu-type timing \
    --bootscript ${WORK_PATH}/m5_outputs/${BENCHNAME}/${BENCHNAME}.sh \
    --big-cpus 16 \
    --little-cpus 0 \
    --caches \
    --kernel ${M5_PATH}/binaries/vmlinux_v4.4_driver \
    --dtb ${M5_PATH}/binaries/armv8_gem5_v1_16cpu.20170616.dtb \
    --disk ${M5_PATH}/disks/cmake-ubuntu18.10-aarch64.1.img \
    --arm-sve-vl 2 \
    > ${RESULTS_PATH}/m5_outputs/${BENCHNAME}/${BENCHNAME}.log 2>&1
#   2>&1 | tee ${WORK_PATH}/m5_outputs/${TIMESTAMPE}/${TIMESTAMPE}.log
#    --debug-flags=VirtualLink,Exec \


#exit( 0 ); 

