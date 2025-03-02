module acuest_gpop_mod
contains
      subroutine acuest_gpop
! MPI version created by Claudia Filippi starting from serial version
! routine to accumulate estimators for energy etc.

      use age, only: ioldest, ioldestmx
      use contrl_file, only: ounit
      use control_dmc, only: dmc_nstep
      use estcum, only: iblk
      use estsum, only: efsum, egsum, esum_dmc
      use estsum, only: pesum_dmc, tausum, tpbsum_dmc
      use estsum, only: wfsum, wgsum, wsum_dmc
      use estcum, only: ecum_dmc, efcum, egcum
      use estcum, only: pecum_dmc, taucum, tpbcum_dmc
      use estcum, only: wcum_dmc, wfcum, wgcum
      use est2cm, only: ecm2_dmc, efcm2, egcm2
      use est2cm, only: pecm2_dmc, tpbcm2_dmc, wcm2
      use est2cm, only: wfcm2, wgcm2
      use force_analytic, only: force_analy_init
      use mmpol,   only: mmpol_init
      use mmpol_dmc, only: mmpol_cum,mmpol_prt
      use mmpol_reduce_mod, only: mmpol_reduce
      use mpi
      use mpiconf, only: wid
      use multiple_geo, only: MFORCE,fgcm2,fgcum,nforce
      use pcm_dmc, only: pcm_cum,pcm_prt
      use pcm_mod, only: pcm_init
      use pcm_reduce_mod, only: pcm_reduce
      use precision_kinds, only: dp
      use prop_dmc, only: prop_prt_dmc
      use prop_reduce_mod, only: prop_reduce
      use properties_mod, only: prop_cum,prop_init

      implicit none

      integer :: i, iegerr, ierr, ifgerr, ifr
      integer :: ioldest_collect, ioldestmx_collect, ipeerr
      integer :: itpber, k, npass
      real(dp) :: dum, efnow, egave, egave1
      real(dp) :: egerr, egnow
      real(dp) :: enow, fgave
      real(dp) :: fgerr, peave, peerr, penow
      real(dp) :: tpbave, tpberr
      real(dp) :: tpbnow, wfnow
      real(dp) :: wgnow, wnow
      real(dp), dimension(MFORCE) :: pecollect
      real(dp), dimension(MFORCE) :: tpbcollect
      real(dp), dimension(MFORCE) :: taucollect
      real(dp), parameter :: zero = 0.d0
      real(dp), parameter :: one = 1.d0

! wt   = weight of configurations
! xsum = sum of values of x from dmc
! xnow = average of values of x from dmc
! xcum = accumulated sums of xnow
! xcm2 = accumulated sums of xnow**2
! xave = current average value of x
! xerr = current error of x

      iblk=iblk+1

      npass=iblk*dmc_nstep

      call mpi_reduce(pesum_dmc,pecollect,MFORCE,mpi_double_precision,mpi_sum,0,MPI_COMM_WORLD,ierr)
      call mpi_reduce(tpbsum_dmc,tpbcollect,MFORCE,mpi_double_precision,mpi_sum,0,MPI_COMM_WORLD,ierr)
      call mpi_reduce(tausum,taucollect,MFORCE,mpi_double_precision,mpi_sum,0,MPI_COMM_WORLD,ierr)

      call mpi_allreduce(ioldest,ioldest_collect,1,mpi_integer,mpi_max,MPI_COMM_WORLD,ierr)
      call mpi_allreduce(ioldestmx,ioldestmx_collect,1,mpi_integer,mpi_max,MPI_COMM_WORLD,ierr)

      ioldest=ioldest_collect
      ioldestmx=ioldestmx_collect

      call prop_reduce(dum)
      call pcm_reduce(dum)
      call mmpol_reduce(dum)


      if(.not.wid) goto 17

      wnow=wsum_dmc/dmc_nstep
      wfnow=wfsum/dmc_nstep
      enow=esum_dmc/wsum_dmc
      efnow=efsum/wfsum

      wcm2=wcm2+wsum_dmc**2
      wfcm2=wfcm2+wfsum**2
      ecm2_dmc=ecm2_dmc+esum_dmc*enow
      efcm2=efcm2+efsum*efnow

      wcum_dmc=wcum_dmc+wsum_dmc
      wfcum=wfcum+wfsum
      ecum_dmc=ecum_dmc+esum_dmc
      efcum=efcum+efsum

      do ifr=1,nforce

        pesum_dmc(ifr)=pecollect(ifr)
        tpbsum_dmc(ifr)=tpbcollect(ifr)
        tausum(ifr)=taucollect(ifr)

        wgnow=wgsum(ifr)/dmc_nstep
        egnow=egsum(ifr)/wgsum(ifr)
        penow=pesum_dmc(ifr)/wgsum(ifr)
        tpbnow=tpbsum_dmc(ifr)/wgsum(ifr)

        wgcm2(ifr)=wgcm2(ifr)+wgsum(ifr)**2
        egcm2(ifr)=egcm2(ifr)+egsum(ifr)*egnow
        pecm2_dmc(ifr)=pecm2_dmc(ifr)+pesum_dmc(ifr)*penow
        tpbcm2_dmc(ifr)=tpbcm2_dmc(ifr)+tpbsum_dmc(ifr)*tpbnow

        wgcum(ifr)=wgcum(ifr)+wgsum(ifr)
        egcum(ifr)=egcum(ifr)+egsum(ifr)
        pecum_dmc(ifr)=pecum_dmc(ifr)+pesum_dmc(ifr)
        tpbcum_dmc(ifr)=tpbcum_dmc(ifr)+tpbsum_dmc(ifr)
        taucum(ifr)=taucum(ifr)+tausum(ifr)

        if(iblk.eq.1) then
          egerr=0
          peerr=0
          tpberr=0
         else
          egerr=errg(egcum(ifr),egcm2(ifr),ifr)
          peerr=errg(pecum_dmc(ifr),pecm2_dmc(ifr),ifr)
          tpberr=errg(tpbcum_dmc(ifr),tpbcm2_dmc(ifr),ifr)
        endif

        egave=egcum(ifr)/wgcum(ifr)
        peave=pecum_dmc(ifr)/wgcum(ifr)
        tpbave=tpbcum_dmc(ifr)/wgcum(ifr)

        if(ifr.gt.1) then
          fgcum(ifr)=fgcum(ifr)+wgsum(1)*(egnow-egsum(1)/wgsum(1))
          fgcm2(ifr)=fgcm2(ifr)+wgsum(1)*(egnow-egsum(1)/wgsum(1))**2
          fgave=egcum(1)/wgcum(1)-egcum(ifr)/wgcum(ifr)
          if(iblk.eq.1) then
            fgerr=0
            ifgerr=0
           else
            fgerr=errg(fgcum(ifr),fgcm2(ifr),1)
            ifgerr=nint(100000* fgerr)
          endif
          egave1=egcum(1)/wgcum(1)
         else
          call prop_cum(wgsum(ifr))
          call pcm_cum(wgsum(ifr))
          call mmpol_cum(wgsum(ifr))
        endif

! write out header first time

        if (iblk.eq.1.and.ifr.eq.1) &
        write(ounit,'(t5,''egnow'',t15,''egave'',t21,''(egerr)'' ,t32&
         ,''peave'',t38,''(peerr)'',t49,''tpbave'',t55,''(tpberr)'',t66&
         ,''fgave'',t74,''(fgerr)'',t85,''npass'',t95,''wgsum'',t101,''ioldest'')')

! write out current values of averages etc.

        iegerr=nint(100000* egerr)
        ipeerr=nint(100000* peerr)
        itpber=nint(100000*tpberr)

        if(ifr.eq.1) then
          write(ounit,'(f10.5,3(f10.5,''('',i5,'')''),17x,3i10)') &
          egsum(ifr)/wgsum(ifr), &
          egave,iegerr,peave,ipeerr,tpbave,itpber,npass, &
          nint(wgsum(ifr)),ioldest

          call prop_prt_dmc(iblk,0,wgcum,wgcm2)
          call pcm_prt(iblk,wgcum,wgcm2)
          call mmpol_prt(iblk,wgcum,wgcm2)
         else
          write(ounit,'(f10.5,4(f10.5,''('',i5,'')''),f10.5,9x,i10)') &
            egsum(ifr)/wgsum(ifr), &
            egave,iegerr,peave,ipeerr,tpbave,itpber, &
            fgave,ifgerr,nint(wgsum(ifr))
        endif
      enddo

!     call flush(6)

! zero out xsum variables for metrop

      17 wsum_dmc=zero
      wfsum=zero
      esum_dmc=zero
      efsum=zero

      do ifr=1,nforce
        egsum(ifr)=zero
        wgsum(ifr)=zero
        pesum_dmc(ifr)=zero
        tpbsum_dmc(ifr)=zero
        tausum(ifr)=zero
      enddo

      call prop_init(1)
      call pcm_init(1)
      call mmpol_init(1)
      call force_analy_init(1)

      return
contains
        elemental pure function rn_eff(w,w2)
          implicit none
          real(dp), intent(in) :: w, w2
          real(dp)             :: rn_eff
          rn_eff=w**2/w2
        end function
        elemental pure function error(x,x2,w,w2)
          implicit none
          real(dp), intent(in) :: x, x2,w,w2
          real(dp)             :: error
          error=dsqrt(max((x2/w-(x/w)**2)/(rn_eff(w,w2)-1),0.d0))
        end function
        elemental pure function errg(x,x2,i)
          implicit none
          real(dp), intent(in) :: x, x2
          integer, intent(in)  :: i
          real(dp)             :: errg
          errg=error(x,x2,wgcum(i),wgcm2(i))
        end function
      end
end module
