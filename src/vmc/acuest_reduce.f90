module acuest_reduce_mod
contains
      subroutine acuest_reduce(enow)
! Written by Claudia Filippi

      use mpi
      use precision_kinds, only: dp
      use multiple_geo, only: MFORCE, nforce, fcm2, fcum
      use csfs, only: nstates
      use mstates_mod, only: MSTATES
      use error, only: fatal_error
      use estcum, only: ecum, pecum, tpbcum, tjfcum, iblk
      use est2cm, only: ecm2, pecm2, tpbcm2, tjfcm2
      use estpsi, only: apsi, aref, detref
      use estsum, only: acc
      use forcewt, only: wcum
      use mpi
      use mpiconf, only: nproc,wid
      use mstates_mod, only: MSTATES
      use multiple_geo, only: MFORCE,fcm2,fcum,nforce
      use optorb_cblock, only: iorbprt,iorbprt_sav
      use pcm_mod, only: pcm_compute_penupv,qpcm_update_vol
      use pcm_reduce_mod, only: pcm_reduce_chvol
      use precision_kinds, only: dp
      use prop_reduce_mod, only: prop_reduce


! this in not even in the master as the line
! is commented in optorb.h !

      use prop_reduce_mod, only: prop_reduce
      use acuest_write_mod, only: acuest_write
      use pcm_mod, only: qpcm_update_vol, pcm_compute_penupv
      use pcm_reduce_mod, only: pcm_reduce_chvol
      use vmc_mod, only: stoo

      implicit none

      integer :: i, iab, ierr, ifr, istate
      integer :: jo, jo_tot, o
      real(dp) :: acollect
      real(dp), dimension(MSTATES, MFORCE) :: enow


      integer mobs
      integer iupdate
      character(len=20) filename

!real, dimension(MSTATES, MFORCE), INTENT(INOUT) :: enow

      real(dp), dimension(:), allocatable  :: local_obs
      real(dp), dimension(:), allocatable  :: collect


      mobs = MSTATES*(8+5*MFORCE)+10
      allocate(local_obs(mobs))
      allocate(collect(mobs))


! ipudate was not declared anywhere
      iupdate = 0

      iblk=iblk+nproc

      jo=0
      do istate=1,nstates

        o=stoo(istate)

        jo=jo+1
        local_obs(jo)=enow(istate,1)

        jo=jo+1
        local_obs(jo)=apsi(istate)
!      enddo

        jo=jo+1
        local_obs(jo)=aref(o)

        do iab=1,2
          jo=jo+1
          local_obs(jo)=detref(iab,o)
        enddo
      enddo

      do ifr=1,nforce
        do istate=1,nstates

          jo=jo+1
          local_obs(jo)=ecum(istate,ifr)

          jo=jo+1
          local_obs(jo)=ecm2(istate,ifr)

          jo=jo+1
          local_obs(jo)=fcum(istate,ifr)

          jo=jo+1
          local_obs(jo)=fcm2(istate,ifr)

          jo=jo+1
          local_obs(jo)=wcum(istate,ifr)
        enddo
      enddo

      do i=1,nstates
        jo=jo+1
        local_obs(jo)=pecum(i)

        jo=jo+1
        local_obs(jo)=tpbcum(i)

        jo=jo+1
        local_obs(jo)=pecm2(i)

        jo=jo+1
        local_obs(jo)=tpbcm2(i)
      enddo

      jo=jo+1
      local_obs(jo)=acc

      jo_tot=jo

      if(jo_tot.gt.mobs)  call fatal_error('ACUEST_REDUCE: increase mobs')

      call mpi_reduce(local_obs,collect,jo_tot &
      ,mpi_double_precision,mpi_sum,0,MPI_COMM_WORLD,ierr)

      call mpi_bcast(collect,jo_tot &
           ,mpi_double_precision,0,MPI_COMM_WORLD,ierr)

      jo=0
      do istate=1,nstates

        o=stoo(istate)

        jo=jo+1
        enow(istate,1)=collect(jo)/nproc

        jo=jo+1
        apsi(istate)=collect(jo)/nproc

        jo=jo+1
        aref(o)=collect(jo)/nproc

        do iab=1,2
          jo=jo+1
          detref(iab,o)=collect(jo)/nproc
        enddo
      enddo

      do ifr=1,nforce
        do istate=1,nstates
          jo=jo+1
          ecum(istate,ifr)=collect(jo)

          jo=jo+1
          ecm2(istate,ifr)=collect(jo)

          jo=jo+1
          fcum(istate,ifr)=collect(jo)

          jo=jo+1
          fcm2(istate,ifr)=collect(jo)

          jo=jo+1
          wcum(istate,ifr)=collect(jo)
        enddo
      enddo

      do i=1,nstates
        jo=jo+1
        pecum(i)=collect(jo)

        jo=jo+1
        tpbcum(i)=collect(jo)

        jo=jo+1
        pecm2(i)=collect(jo)

        jo=jo+1
        tpbcm2(i)=collect(jo)
      enddo

      jo=jo+1
      acollect=collect(jo)

! reduce properties
      call prop_reduce
! optimization reduced at the end of the run: large vectors to pass
! pcm averages reduced at the end of the run


      if(wid) then

        acc=acollect

! optorb reduced at the end of the run: set printout to 0
        iorbprt_sav=iorbprt
        iorbprt=0
        call acuest_write(enow,nproc)
        iorbprt=iorbprt_sav

       else

        do ifr=1,nforce
          do istate=1,nstates
           ecum(istate,ifr)=0
           ecm2(istate,ifr)=0
           fcum(istate,ifr)=0
           fcm2(istate,ifr)=0
           wcum(istate,ifr)=0
          enddo
        enddo

        do i=1,nstates
          pecum(i)=0
          tpbcum(i)=0
          pecm2(i)=0
          tpbcm2(i)=0
        enddo

        acc=0
      endif

      if (allocated(local_obs)) deallocate(local_obs)
      if (allocated(collect)) deallocate(collect)

      end subroutine

      subroutine acues1_reduce
      use pcm_mod, only: pcm_compute_penupv,qpcm_update_vol
      use pcm_reduce_mod, only: pcm_reduce_chvol
      implicit none
      integer iupdate

      call qpcm_update_vol(iupdate)
      if(iupdate.eq.1) then
        call pcm_reduce_chvol
        call pcm_compute_penupv
      endif

      return

      end
end module
