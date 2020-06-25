module m_diffusion_openmp
  implicit none
  private

  public :: apply_diffusion
  contains
    subroutine apply_diffusion(in_field, out_field, num_halo, alpha, p, num_iter)
      use, intrinsic :: iso_fortran_env, only: REAL32
      use m_partitioner, only: Partitioner
      use m_halo_mpi, only: update_halo

      real(kind = REAL32), intent(inout) :: in_field(:, :, :)
      real(kind = REAL32), intent(inout) :: out_field(:, :, :)
      integer, intent(in) :: num_halo
      real(kind = REAL32), intent(in) :: alpha
      type(Partitioner), intent(in) :: p
      integer, intent(in) :: num_iter

      integer :: iter
      integer :: i
      integer :: j
      integer :: k
      real(kind = REAL32) :: alpha_20
      real(kind = REAL32) :: alpha_08
      real(kind = REAL32) :: alpha_02
      real(kind = REAL32) :: alpha_01
      integer :: nx
      integer :: ny
      integer :: nz

      nx = size(in_field, 1) - 2 * num_halo
      ny = size(in_field, 2) - 2 * num_halo
      nz = size(in_field, 3)

      alpha_20 = -20 * alpha + 1
      alpha_08 =   8 * alpha
      alpha_02 =  -2 * alpha
      alpha_01 =  -1 * alpha

      !$omp parallel &
      !$omp   default(none) &
      !$omp   shared(nx, ny, nz, num_halo, num_iter, in_field, out_field, alpha_20, alpha_08, alpha_02, alpha_01, p) &
      !$omp   private(iter, i, j, k)
      do iter = 1, num_iter
        call update_halo(in_field, num_halo, p)

        !$omp do schedule(dynamic)
        do k = 1, nz
          !$omp simd collapse(2)
          do j = 1 + num_halo, ny + num_halo
            do i = 1 + num_halo, nx + num_halo
              out_field(i, j, k) = &
                + alpha_20 * in_field(i,     j,     k) &
                + alpha_08 * in_field(i - 1, j,     k) &
                + alpha_08 * in_field(i + 1, j,     k) &
                + alpha_08 * in_field(i,     j - 1, k) &
                + alpha_08 * in_field(i,     j + 1, k) &
                + alpha_02 * in_field(i - 1, j - 1, k) &
                + alpha_02 * in_field(i - 1, j + 1, k) &
                + alpha_02 * in_field(i + 1, j - 1, k) &
                + alpha_02 * in_field(i + 1, j + 1, k) &
                + alpha_01 * in_field(i - 2, j,     k) &
                + alpha_01 * in_field(i + 2, j,     k) &
                + alpha_01 * in_field(i,     j - 2, k) &
                + alpha_01 * in_field(i,     j + 2, k)
            end do
          end do

          if (iter /= num_iter) then
            !$omp simd collapse(2)
            do j = 1 + num_halo, ny + num_halo
              do i = 1 + num_halo, nx + num_halo
                in_field(i, j, k) = out_field(i, j, k)
              end do
            end do
          end if
        end do
        !$omp end do

        if (iter == num_iter) then
          call update_halo(out_field, num_halo, p)
        end if
      end do
      !$omp end parallel
    end subroutine
end module

! vim: set filetype=fortran expandtab tabstop=2 softtabstop=2 shiftwidth=2 :