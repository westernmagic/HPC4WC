#!/bin/bash

num_iter=1024
size=1024
nx=${size}
ny=${size}

export OMP_NUM_THREADS=12
for n in {63,62,61,60,59,58,57,56,55,54,53,52,51,50,49,48}
do
    echo "zmax $n"
    nz=${n}
    for count in {1..5}
    do
        srun ./arrayFusionACC.x --nx ${nx} --ny ${ny} --nz ${nz} --num_iter ${num_iter}
    done 
done 