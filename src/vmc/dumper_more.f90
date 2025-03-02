      module dumper_more_mod

      use basis,   only: zex
      use constants, only: hb
      use control_vmc, only: vmc_nstep
      use contrl_file, only: errunit,ounit
      use csfs,    only: nstates
      use determinant_psig_mod, only: determinant_psig
      use determinante_mod, only: compute_determinante_grad
      use coefs, only: nbasis
      use config, only: eold, nearesto, psi2o
      use config, only: psido, psijo, rmino, rvmino
      use config, only: vold, xnew, xold
      use csfs, only: nstates
      use error,   only: fatal_error
      use est2cm, only: ecm2, ecm21, pecm2, tpbcm2
      use estcum, only: ecum, ecum1, iblk, pecum, tpbcum
      use estsig, only: ecm21s, ecum1s
      use estsum, only: acc, esum, pesum, tpbsum
      use forcewt, only: wcum, wsum
      use force_analytic, only: force_analy_dump,force_analy_rstrt
      use hpsi_mod, only: hpsi
      use inputflags, only: eps_node_cutoff,node_cutoff
      use metropolis, only: delta, deltar, deltat
      use mstates_ctrl, only: iguiding
      use mstates_mod, only: MSTATES
      use multiple_geo, only: nforce, iwftype, nwftype, pecent
      use multiple_geo, only: fcm2, fcum
      use multiple_geo, only: fcm2,fcum,iwftype,nforce,nwftype,pecent
      use multiple_states, only: efficiency_dump,efficiency_rstrt
      use nodes_distance_mod, only: nodes_distance,rnorm_nodes_num
      use optci_mod, only: optci_dump,optci_rstrt,optci_save
      use optwf_control, only: ioptorb
      use optjas_mod, only: optjas_dump,optjas_rstrt,optjas_save
      use optorb_cblock, only: ns_current
      use optorb_f_mod, only: optorb_dump,optorb_rstrt,optorb_save
      use optwf_control, only: ioptorb
      use optx_jas_ci, only: optx_jas_ci_dump,optx_jas_ci_rstrt
      use optx_jas_orb, only: optx_jas_orb_dump,optx_jas_orb_rstrt
      use optx_orb_ci, only: optx_orb_ci_dump,optx_orb_ci_rstrt
      use pcm_mod, only: pcm_dump,pcm_rstrt
      use precision_kinds, only: dp
      use prop_vmc, only: prop_save
      use properties_mod, only: prop_dump,prop_rstrt
      use slater,  only: cdet,coef,ndet,norb
      use stats, only: rejmax
      use step, only: ekin, ekin2, suc, trunfb, try
      use strech_mod, only: setup_force,strech
      use system, only: znuc, cent, iwctype, nctype, ncent, ncent_tot, nctype_tot
      use system, only: newghostype, nghostcent, nelec, ndn, nup
      use vmc_mod, only: norb_tot
      use vmc_mod, only: nrad, stoj
      use system,  only: cent,iwctype,ncent,ncent_tot,nctype,nctype_tot
      use system,  only: ndn,nelec,newghostype,nghostcent,nup,znuc
      use vmc_mod, only: norb_tot,nrad

      implicit none

contains
      subroutine dumper_more
      implicit none
      integer :: i, ib, ic, ifr, istate
      integer :: j, jel, k, nbasx
      integer :: ncentx, nctypex, ndetx, ndnx
      integer :: newghostypex, nghostcentx, norbx, nstepx
      integer :: nupx

      real(dp) :: ajacob, deltarx
      real(dp) :: deltatx, deltax, dist, distance_node
      real(dp) :: pecx, psidg, rnorm_nodes
      real(dp), dimension(nbasis,norb_tot) :: coefx
      real(dp), dimension(nbasis) :: zexx
      real(dp), dimension(3,ncent_tot) :: centx
      real(dp), dimension(nctype_tot) :: znucx
      real(dp), dimension(ndet) :: cdetx
      real(dp), dimension(3,nelec) :: xstrech
      real(dp), dimension(MSTATES) :: ekino
      real(dp), parameter :: half = 0.5d0
      real(dp), parameter :: small = 1.d-6

      write(10) delta,deltar,deltat

      write(10) vmc_nstep,iblk
      do istate=1,nstates
        write(10) ecum1(istate),(ecum(istate,i),i=1,nforce),pecum(istate),tpbcum(istate),acc
        write(10) ecm21(istate),(ecm2(istate,i),i=1,nforce),pecm2(istate),tpbcm2(istate)
        if(nforce.gt.1) then
          write(10) (wcum(istate,i),fcum(istate,i),fcm2(istate,i),i=1,nforce)
         else
          write(10) wcum(istate,1)
        endif
        write(10) ecum1s(istate),ecm21s(istate)
      enddo
      write(10) (try(i),suc(i),trunfb(i),ekin(i),ekin2(i),i=1,nrad)
      call optorb_dump(10)
      call optci_dump(10)
      call prop_dump(10)
      call efficiency_dump(10)
      call pcm_dump(10)
      call force_analy_dump(10)
      write(10) rejmax

      write(10) nbasis,norb
      write(10) ((coef(ib,i,1),ib=1,nbasis),i=1,norb)
      write(10) (zex(ib,1),ib=1,nbasis)
      write(10) nctype,ncent,newghostype,nghostcent,(iwctype(i),i=1,ncent+nghostcent)
      write(10) ((cent(k,ic),k=1,3),ic=1,ncent+nghostcent)
      write(10) pecent
      write(10) (znuc(i),i=1,nctype)
      write(10) (cdet(i,1,1),i=1,ndet)
      write(10) ndet,nup,ndn

      call optjas_dump(10)
      call optx_jas_orb_dump(10)
      call optx_jas_ci_dump(10)
      call optx_orb_ci_dump(10)

      rewind 10

      write(ounit,'(1x,''successful dump to unit 10'')')

      end subroutine

!-----------------------------------------------------------------------
      subroutine startr_more
      implicit none
      integer :: i, ib, ic, ifr, istate
      integer :: j, jel, k, nbasx
      integer :: ncentx, nctypex, ndetx, ndnx
      integer :: newghostypex, nghostcentx, norbx, nstepx
      integer :: nupx

      real(dp) :: ajacob, deltarx
      real(dp) :: deltatx, deltax, dist, distance_node
      real(dp) :: pecx, psidg, rnorm_nodes
      real(dp), dimension(nbasis,norb_tot) :: coefx
      real(dp), dimension(nbasis) :: zexx
      real(dp), dimension(3,ncent_tot) :: centx
      real(dp), dimension(nctype_tot) :: znucx
      real(dp), dimension(ndet) :: cdetx
      real(dp), dimension(3,nelec) :: xstrech
      real(dp), dimension(MSTATES) :: ekino
      real(dp), parameter :: half = 0.5d0
      real(dp), parameter :: small = 1.d-6

      read(10) deltax,deltarx,deltatx
      if (dabs(deltax-delta).gt.small) call fatal_error('STARTR: delta')
      if (dabs(deltarx-deltar).gt.small) call fatal_error('STARTR: deltar')
      if (dabs(deltatx-deltat).gt.small) call fatal_error('STARTR: deltat')

      read(10) nstepx,iblk
      if (nstepx.ne.vmc_nstep) call fatal_error('STARTR: nstep')
      do istate=1,nstates
        read(10) ecum1(istate),(ecum(istate,i),i=1,nforce),pecum(istate),tpbcum(istate),acc
        read(10) ecm21(istate),(ecm2(istate,i),i=1,nforce),pecm2(istate),tpbcm2(istate)
        if(nforce.gt.1) then
          read(10) (wcum(istate,i),fcum(istate,i),fcm2(istate,i),i=1,nforce)
         else
          read(10) wcum(istate,1)
        endif
        read(10) ecum1s(istate),ecm21s(istate)
      enddo
      read(10) (try(i),suc(i),trunfb(i),ekin(i),ekin2(i),i=1,nrad)

      call prop_rstrt(10)
      call optorb_rstrt(10)
      call optci_rstrt(10)
      call efficiency_rstrt(10)
      call pcm_rstrt(10)
      call force_analy_rstrt(10)
      read(10) rejmax

      read(10) nbasx,norbx
      if (nbasx.ne.nbasis) call fatal_error('STARTR: nbasis')
      if (norbx.ne.norb) call fatal_error('STARTR: norb')
      read(10) ((coefx(ib,i),ib=1,nbasis),i=1,norb)
      read(10) (zexx(ib),ib=1,nbasis)
      read(10) nctypex,ncentx,newghostypex,nghostcentx,(iwctype(i),i=1,ncentx+nghostcentx)
      if (ncentx.ne.ncent) call fatal_error('STARTR: ncent')
      if (nctypex.ne.nctype) call fatal_error('STARTR: nctype')
      read(10) ((centx(k,ic),k=1,3),ic=1,ncentx+nghostcentx)
      read(10) pecx
      read(10) (znucx(i),i=1,nctype)
      do j=1,norb
        do i=1,nbasis
          if (dabs(coefx(i,j)-coef(i,j,1)).gt.small) call fatal_error('STARTR: coef')
        enddo
      enddo
      do i=1,nbasis
        if (dabs(zexx(i)-zex(i,1)).gt.small) call fatal_error('STARTR: zex')
      enddo
      do i=1,ncent+nghostcent
        do k=1,3
          if (dabs(cent(k,i)-centx(k,i)).gt.small) call fatal_error('STARTR: cent')
        enddo
      enddo
      if (pecx.ne.pecent) call fatal_error('STARTR: pec')
      do i=1,nctype
        if (dabs(znucx(i)-znuc(i)).gt.small) call fatal_error('STARTR: znuc')
      enddo
      read(10) (cdetx(i),i=1,ndet)
      read(10) ndetx,nupx,ndnx
      do i=1,ndet
        if (dabs(cdetx(i)-cdet(i,1,1)).gt.small) call fatal_error('STARTR: cdet')
      enddo
      if (ndetx.ne.ndet) call fatal_error('STARTR: ndet')
      if (nupx.ne.nup) call fatal_error('STARTR: nup')
      if (ndnx.ne.ndn) call fatal_error('STARTR: ndn')

      call optjas_rstrt(10)
      call optx_jas_orb_rstrt(10)
      call optx_jas_ci_rstrt(10)
      call optx_orb_ci_rstrt(10)

      write(ounit,'(1x,''succesful read from unit 10'')')
      write(ounit,'(t5,''enow'',t15,''eave'',t25,''eerr'',t35,''peave'',t45,''peerr'',t55,''tpbave'',t65,''tpberr'',t75,''accept'',t85,''iter'')')

      if(nforce.gt.1) then
        call setup_force
       else
        nwftype=1
        iwftype(1)=1
      endif

! loop over secondary config
      do ifr=2,nforce
! set n- and e-coord and n-n potential
        call strech(xold,xstrech,ajacob,ifr,1)
        call hpsi(xstrech,psido,psijo,ekino,eold(1,ifr),0,ifr)
        do istate=1,nforce
          psi2o(istate,ifr)=2*(dlog(dabs(psido(istate)))+psijo(stoj(istate)))+dlog(ajacob)
        enddo
      enddo

! primary config
! set n-coord and n-n potential
      if(nforce.gt.1) call strech(xold,xstrech,ajacob,1,0)
      call hpsi(xold,psido,psijo,ekino,eold(1,1),0,1)
      do istate=1,nforce
        psi2o(istate,1)=2*(dlog(dabs(psido(istate)))+psijo(stoj(istate)))
      enddo

      if(iguiding.gt.0) then
        call determinant_psig(psido,psijo,psidg)
! rewrite psi2o if you are sampling guiding
        psi2o(1,1)=2*(dlog(dabs(psidg)))
      endif

      if(node_cutoff.gt.0) then
        do jel=1,nelec
          call compute_determinante_grad(jel,psido(1),psido,psijo,vold(1,jel),1)
        enddo
        call nodes_distance(vold,distance_node,1)
        rnorm_nodes=rnorm_nodes_num(distance_node,eps_node_cutoff)/distance_node

        psi2o(1,1)=psi2o(1,1)+2*dlog(rnorm_nodes)
      endif

      if(ioptorb.gt.0) ns_current=0

      call prop_save
      call optjas_save
      call optci_save
      call optorb_save

      do i=1,nelec
        do k=1,3
          xnew(k,i)=xold(k,i)
        enddo
      enddo

      do i=1,nelec
        rmino(i)=99.d9
        do j=1,ncent
          dist=0
          do k=1,3
            dist=dist+(xold(k,i)-cent(k,j))**2
          enddo
          if(dist.lt.rmino(i)) then
            rmino(i)=dist
            nearesto(i)=j
          endif
        enddo
        rmino(i)=dsqrt(rmino(i))
        do k=1,3
          rvmino(k,i)=xold(k,i)-cent(k,nearesto(i))
        enddo
      enddo

      do istate=1,nstates
        do ifr=1,nforce
          esum(istate,ifr)=0
          wsum(istate,ifr)=0
        enddo
        pesum(istate)=0
        tpbsum(istate)=0
      enddo

      return
      end
end module
