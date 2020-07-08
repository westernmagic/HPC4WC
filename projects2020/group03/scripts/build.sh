#!/bin/bash

# set -euo pipefail
IFS=$'\n\t'

compilers=(
	"gnu"
	"intel"
	"cray"
	"pgi"
)

cd $(dirname ${BASH_SOURCE[0]})/..

mkdir -p build
cd build

BUILD_TYPE=${1:-Release}
PRGENV=$(module list 2>&1 | sed -E -n -e 's!.*(PrgEnv-\w+)/.*!\1!p')

for compiler in ${compilers[@]}; do
	echo "Building ${BUILD_TYPE} using ${compiler}"
	mkdir -p ${compiler}
	cd ${compiler}

	module switch ${PRGENV} PrgEnv-${compiler}
	if [[ "${compiler}" == "gnu" ]]; then
		module unload perftools-lite-gpu
	else
		module load perftools-lite-gpu
	fi
	if [[ "${compiler}" == "gnu" || "${compiler}" == "cray" ]]; then
		module load craype-accel-nvidia60
	else
		module unload craype-accel-nvidia60 cray-libsci_acc
	fi

	cmake -D CMAKE_BUILD_TYPE=${BUILD_TYPE} ../..
	cmake --build .

	module switch PrgEnv-${compiler} ${PRGENV}
	cd ..
done