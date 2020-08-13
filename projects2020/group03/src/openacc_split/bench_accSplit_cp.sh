#!/bin/bash

num_iter=1024
nz=64
# nx=128 
# ny=128 

export OMP_NUM_THREADS=12
for size in {512,1024}
do
    nx=${size}
    ny=${size}
    for n in {64,63,62,61,60,59,58,57,56,55,54,53,52,51,50,49,48}
    do
        num_split=${n}
        echo "running on gpu : $num_split slices"
        for count in {1..4}
        do 
            srun ./arrayFusionACCSplit.x --nx ${nx} --ny ${ny} --nz ${nz} --num_iter ${num_iter} --numSplit ${num_split}  
        done 
    done 
done
    
    
#     cd /users/course07/HPC4WC_3/HPC4WC/projects2020/group03/src/openacc_split
# 