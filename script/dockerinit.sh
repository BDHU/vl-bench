#!/bin/bash

docker run \
    -v ~/boost_1_63_0:/boost_1_63_0 \
    -v ~/vl-bench:/vl-bench \
    -d --privileged --name gem5 jonbea01/ubuntu-x86-gem5:16Mar2021CDT1726 \
    tail -f /dev/null

docker exec -it gem5 bash
