module mmpol_dmc
contains
      subroutine mmpol_prt(iblk,wgcum,wgcm2)

      use contrl_file, only: ounit
      use control_dmc, only: dmc_nconf,dmc_nstep
      use mmpol_averages, only: cmmpol_cm2,cmmpol_cum,dmmpol_cm2
      use mmpol_averages, only: dmmpol_cum
      use mmpol_cntrl, only: immpol,immpolprt
      use multiple_geo, only: MFORCE
      use precision_kinds, only: dp
!      use contrl, only: nconf, nstep
      implicit none

      integer :: i, iblk, icmmpol_err, idmmpol_err
      real(dp) :: cekcal, cmmpol_ave, cmmpol_err, cmmpol_kcal, dckcal
      real(dp) :: dekcal, dmmpol_ave, dmmpol_err, dmmpol_kcal
      real(dp) :: evalg_eff, hatokc
      real(dp) :: rtevalg_eff1, w, w2
      real(dp) :: x, x2
      real(dp), dimension(MFORCE) :: wgcum
      real(dp), dimension(MFORCE) :: wgcm2

      data hatokc/627.509541d0/


      if(immpol.eq.0.or.immpolprt.eq.0) return

      dmmpol_ave=dmmpol_cum/wgcum(1)
      cmmpol_ave=cmmpol_cum/wgcum(1)

      if(iblk.eq.1) then
        dmmpol_err=0
        cmmpol_err=0
       else
        dmmpol_err=errg(dmmpol_cum,dmmpol_cm2,1)
        cmmpol_err=errg(cmmpol_cum,cmmpol_cm2,1)

        idmmpol_err=nint(100000*dmmpol_err)
        icmmpol_err=nint(100000*cmmpol_err)
      endif

      evalg_eff=dmc_nconf*dmc_nstep*rn_eff(wgcum(1),wgcm2(1))
      rtevalg_eff1=dsqrt(evalg_eff-1)

      dmmpol_kcal=dmmpol_ave*hatokc
      cmmpol_kcal=cmmpol_ave*hatokc
      dekcal=dmmpol_err*hatokc
      cekcal=cmmpol_err*hatokc
      dckcal=dmmpol_kcal+cmmpol_kcal

      write(ounit,*)'    <H(QM/MM)/dipoles/charges/tot +- err (kcal/mol) '
      write(ounit,1000) dmmpol_kcal,dekcal,cmmpol_kcal,cekcal,dckcal
      write(ounit,*)'    <H(QM/MM)/dipoles/charges/tot +- err (hartree) '
      write(ounit,1000) dmmpol_ave,dmmpol_err,cmmpol_ave,cmmpol_err,dckcal/hatokc
      write(ounit,*)
      1000 format (f15.7,' +- ',2f15.7,' +- ',f15.7,' --> ',f15.7)

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
!-----------------------------------------------------------------------
      subroutine mmpol_fin(iblk,wgcum,wgcm2)

      use mmpol_cntrl, only: immpol, immpolprt
      use multiple_geo, only: MFORCE

      use precision_kinds, only: dp

      implicit none

      integer :: iblk, immpolprt_sav

      real(dp), dimension(MFORCE) :: wgcum
      real(dp), dimension(MFORCE) :: wgcm2




      if(immpol.eq.0) return

      immpolprt_sav=immpolprt
      immpolprt=1
      call mmpol_prt(iblk,wgcum(1),wgcm2(1))
      immpolprt=immpolprt_sav

      return
      end
!-----------------------------------------------------------------------
      subroutine mmpol_save(iw)

      use mmpol_cntrl, only: immpol
      use mmpol_hpsi, only: eek_pol
      use mmpol_parms, only: nchmm
      use mmpolo,  only: cmmpolo_dmc,dmmpolo_dmc,eeko1,eeko2,eeko3
      use precision_kinds, only: dp

      implicit none

      integer :: i, iw
      real(dp) :: QMdp = 0, QMq = 0

      if(immpol.eq.0) return

      dmmpolo_dmc(iw)=QMdp
      cmmpolo_dmc(iw)=QMq

      do i=1,nchmm
        eeko1(iw,i)=eek_pol(1,i)
        eeko2(iw,i)=eek_pol(2,i)
        eeko3(iw,i)=eek_pol(3,i)
      enddo

      return
      end
!-----------------------------------------------------------------------
      subroutine mmpol_sum(p,q,iw)

      use mmpol_averages, only: cmmpol_sum,dmmpol_sum,eek_sum
      use mmpol_cntrl, only: immpol
      use mmpol_hpsi, only: eek_pol
      use mmpol_parms, only: nchmm
      use mmpolo,  only: cmmpolo_dmc,dmmpolo_dmc,eeko1,eeko2,eeko3
      use precision_kinds, only: dp

      implicit none

      integer :: i, iw
      real(dp) :: QMdp = 0, QMq = 0, p, q

      if(immpol.eq.0) return

      dmmpol_sum=dmmpol_sum+p*QMdp+q*dmmpolo_dmc(iw)
      cmmpol_sum=cmmpol_sum+p*QMq+q*cmmpolo_dmc(iw)

      do i=1,nchmm
        eek_sum(1,i)= eek_sum(1,i)+p*eek_pol(1,i)+q*eeko1(iw,i)
        eek_sum(2,i)= eek_sum(2,i)+p*eek_pol(2,i)+q*eeko2(iw,i)
        eek_sum(3,i)= eek_sum(3,i)+p*eek_pol(3,i)+q*eeko3(iw,i)
      enddo

      return
      end
!-----------------------------------------------------------------------
      subroutine mmpol_cum(wsum_dmc)

      use mmpol_averages, only: cmmpol_cm2,cmmpol_cum,cmmpol_sum
      use mmpol_averages, only: dmmpol_cm2,dmmpol_cum,dmmpol_sum
      use mmpol_averages, only: eek1_cm2,eek1_cum,eek2_cm2,eek2_cum
      use mmpol_averages, only: eek3_cm2,eek3_cum,eek_sum
      use mmpol_cntrl, only: immpol
      use mmpol_parms, only: nchmm
      use precision_kinds, only: dp
      implicit none

      integer :: i !, immpol, nchmm
      real(dp) :: cmmpolnow, dmmpolnow, eek_now1, eek_now2, eek_now3
      real(dp) :: wsum_dmc

      if(immpol.eq.0) return

      dmmpolnow=dmmpol_sum/wsum_dmc
      cmmpolnow=cmmpol_sum/wsum_dmc

      dmmpol_cm2=dmmpol_cm2+dmmpol_sum*dmmpolnow
      cmmpol_cm2=cmmpol_cm2+cmmpol_sum*cmmpolnow

      dmmpol_cum=dmmpol_cum+dmmpol_sum
      cmmpol_cum=cmmpol_cum+cmmpol_sum

      do i=1,nchmm
        eek_now1=eek_sum(1,i)/wsum_dmc
        eek1_cm2(i)=eek1_cm2(i)+eek_sum(1,i)*eek_now1
        eek1_cum(i)=eek1_cum(i)+eek_sum(1,i)

        eek_now2=eek_sum(2,i)/wsum_dmc
        eek2_cm2(i)=eek2_cm2(i)+eek_sum(2,i)*eek_now2
        eek2_cum(i)=eek2_cum(i)+eek_sum(2,i)

        eek_now3=eek_sum(3,i)/wsum_dmc
        eek3_cm2(i)=eek3_cm2(i)+eek_sum(3,i)*eek_now3
        eek3_cum(i)=eek3_cum(i)+eek_sum(3,i)

      enddo

      return
      end
!-----------------------------------------------------------------------
      subroutine mmpol_splitj(iw,iw2)

      use mmpol_parms, only: nchmm
      use mmpolo,  only: cmmpolo_dmc,dmmpolo_dmc,eeko1,eeko2,eeko3

      implicit none

      integer :: i, iw, iw2  !, nchmm


      dmmpolo_dmc(iw2)=dmmpolo_dmc(iw)
      cmmpolo_dmc(iw2)=cmmpolo_dmc(iw)

      do i=1,nchmm
        eeko1(iw2,i)=eeko1(iw,i)
        eeko2(iw2,i)=eeko2(iw,i)
        eeko3(iw2,i)=eeko3(iw,i)
      enddo

      return
      end
end module
