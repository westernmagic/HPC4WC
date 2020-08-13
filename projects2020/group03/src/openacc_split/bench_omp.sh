#!/bin/bash

num_iter=1024
nx=128 
ny=128 

export OMP_NUM_THREADS=12
for n in {1..16}
do
    nz=${n}
    echo "z max : $nz "
    for count in {1..10}
    do
        srun ./omp.x --nx ${nx} --ny ${ny} --nz ${nz} --num_iter ${num_iter}  
    done 
done 