#include <chrono>
#include <fstream>
#include <omp.h>
#include <iostream>

#include "utils.h"

void updateHalo2d(Storage3D<double>& inField, int k) {
  int xInterior = inField.xMax() - inField.xMin();
  int yInterior = inField.yMax() - inField.yMin();

  // bottom edge (without corners)
    for(std::size_t j = 0; j < inField.yMin(); ++j) {
        for(std::size_t i = inField.xMin(); i < inField.xMax(); ++i) {
      inField(i, j, k) = inField(i, j + yInterior, k);
    }
  }

  // top edge (without corners)
  
    for(std::size_t j = inField.yMax(); j < inField.ySize(); ++j) {
        for(std::size_t i = inField.xMin(); i < inField.xMax(); ++i) {
      inField(i, j, k) = inField(i, j - yInterior, k);
    }
  }

  // left edge (including corners)
  
    for(std::size_t j = inField.yMin(); j < inField.yMax(); ++j) {
        for(std::size_t i = 0; i < inField.xMin(); ++i) {
      inField(i, j, k) = inField(i + xInterior, j, k);
    }
  }

  // right edge (including corners)
  
    for(std::size_t j = inField.yMin(); j < inField.yMax(); ++j) {
        for(std::size_t i = inField.xMax(); i < inField.xSize(); ++i) {
      inField(i, j, k) = inField(i - xInterior, j, k);
    }
  }
}

void apply_diffusion(Storage3D<double>& inField, Storage3D<double>& outField, double alpha,
                     unsigned numIter, int x, int y, int z, int halo) {

  Storage3D<double> tmp1Field(x, y, z, halo);

  for(std::size_t iter = 0; iter < numIter; ++iter) {
 #pragma omp parallel for schedule (static,1)
    for(std::size_t k = 0; k < inField.zMax(); ++k) {
      updateHalo2d(inField, k);

      // apply the initial laplacian
      for(std::size_t j = inField.yMin() - 1; j < inField.yMax() + 1; ++j) {
        for(std::size_t i = inField.xMin() - 1; i < inField.xMax() + 1; ++i) {
          tmp1Field(i, j, 0) = -4.0 * inField(i, j, k) + inField(i - 1, j, k) +
                               inField(i + 1, j, k) + inField(i, j - 1, k) + inField(i, j + 1, k);
        }
      }

      // apply the second laplacian
      for(std::size_t j = inField.yMin(); j < inField.yMax(); ++j) {
        for(std::size_t i = inField.xMin(); i < inField.xMax(); ++i) {
          double laplap = -4.0 * tmp1Field(i, j, 0) + tmp1Field(i - 1, j, 0) +
                          tmp1Field(i + 1, j, 0) + tmp1Field(i, j - 1, 0) + tmp1Field(i, j + 1, 0);

          // and update the field
          if(iter == numIter - 1) {
            outField(i, j, k) = inField(i, j, k) - alpha * laplap;
          } else {
            inField(i, j, k) = inField(i, j, k) - alpha * laplap;
          }
        }
      }
    }
  }
}

void reportTime(const Storage3D<double>& storage, int nIter, double diff) {
  std::cout << "# ranks nx ny ny nz num_iter time\ndata = np.array( [ \\\n";
  int size;
#pragma omp parallel
  {
#pragma omp master
    { size = omp_get_num_threads(); }
  }
  std::cout << "[ " << size << ", " << storage.xMax()- storage.xMin() << ", " << storage.yMax() - storage.yMin()<< ", "
            << storage.zMax() << ", " << nIter << ", " << diff << "],\n";
  std::cout << "] )" << std::endl;
}

int main(int argc, char const* argv[]) {
  int x = atoi(argv[1]);
  int y = atoi(argv[2]);
  int z = atoi(argv[3]);
  int iter = atoi(argv[4]);
  Storage3D<double> input(x, y, z, 3);
  input.initialize();
  Storage3D<double> output(x, y, z, 3);
  output.initialize();

  double alpha = 1. / 32.;

  std::ofstream fout;
  fout.open("in_field.dat", std::ios::binary | std::ofstream::trunc);
  input.writeFile(fout);
  fout.close();

  auto start = std::chrono::steady_clock::now();

  apply_diffusion(input, output, alpha, iter, x, y, z, 3);

  auto end = std::chrono::steady_clock::now();

  fout.open("out_field.dat", std::ios::binary | std::ofstream::trunc);
  output.writeFile(fout);
  fout.close();

  auto diff = end - start;
  double timeDiff = std::chrono::duration<double, std::milli>(diff).count() / 1000.;
  reportTime(output, iter, timeDiff);

  return 0;
}