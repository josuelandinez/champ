The Cornell-Holland Ab-initio Materials Package (CHAMP) is a quantum Monte Carlo 
suite of programs for electronic structure calculations of atomic and molecular systems. 
The code is a sister code of the homonymous program originally developed by Cyrus Umrigar 
and Claudia Filippi of which it retains the accelerated Metropolis method and the efficient 
diffusion Monte Carlo algorithms.

The European branch of the code is currently developed by Claudia Filippi and Saverio Moroni, 
with significant contributions by Claudio Amovilli and other collaborators.

CHAMP has three basic capabilities:

* Metropolis or variational Monte Carlo (VMC)
* Diffusion Monte Carlo (DMC)
* Optimization of many-body wave functions by energy minimization (VMC) for ground and excited states

Noteworthy features of CHAMP are:

* Efficient wave function optimization also in a state-average fashion for multiple states of the same symmetry (VMC)
* Efficient computation of analytical interatomic forces (VMC)
* Compact formulation for a fast evaluation of multi-determinant expansions and their derivatives (VMC and DMC)
* Multiscale VMC and DMC calculations in classical point charges (MM), polarizable continuum model (PCM), and polarizable force fields (MMpol)

**NOTE**

You should neither obtain this program from any other source nor should you distribute it 
or any portion thereof to any person, including people in the same research group.

It is expected that users of the programs will do so in collaboration
with one of the principal authors.  This serves to ensure both that the
programs are used correctly and that the principal authors get adequate
scientific credit for the time invested in developing the programs.

**Usual disclaimer**  

The authors make no claims about the correctness of
the program suite and people who use it do so at their own risk.

------------------------------------------------------------------------

CHAMP relies on various other program packages:

1. Parser2: 
   An easy-to-use and easy-to-extend keyword based input facility for fortran 
   programs written by Friedemann Schautz.

2. GAMESS:
   For finite systems the starting wavefunction is obtained from the
   quantum chemistry program GAMESS, written by Mike Schmidt and
   collaborators at Iowa State University.  

3. GAMESS_Interface:
   The wavefunction produced by GAMESS has to be cast in a form
   suitable for input to CHAMP.  This is a lot more work than first meets
   the eye. The Perl script was written by Friedemann Schautz.

4. MOLCAS_Interface: recently added thanks to Csaba Daday and Monika Dash

### Run on CCPGate
In the new version (without filename) run with:
```
mpirun -s all -np "n process" -machinefile "machinefile"

```
NOTE OpenMPI: Not tested but most likely will not work at the moment as the stdin cannot be redirected to all tasks.

### Installation Using CMake
To install **Champ** using [cmake](https://cmake.org/) you need to run the following commands:
```
cmake -H. -Bbuild
cmake --build build -- -j4
```
The first command is only required to set up the build directory and needs to be
executed only once. Compared to the previous Makefiles the dependencies for the
include files (e.g include/vmc.h) are correctly setup and no `--clean-first` is
required.

#### CMAKE Options

To select a given compiler, you can type:
```
cmake -H. -Bbuild -D CMAKE_Fortran_COMPILER=ifort 
```
To use LAPACK and BLAS installed locally, include the path to the libraries:
```
cmake -H. -Bbuild -D CMAKE_Fortran_COMPILER=ifort -D BLAS_blas_LIBRARY=/home/user/lib/BLAS/blas_LINUX.a -D LAPACK_lapack_LIBRARY=/home/user/lib/LAPACK/liblapack.a
```
To compile only e.g. VMC serial:
```
cmake --build build --target vmc.mov1
```
Clean and build:
```
cmake --build build --clean-first
```
Compared to the previous Makefiles the dependencies for the include files
(e.g include/vmc.h) are correctly setup and no `--clean-first` is required.

#### CMAKE Recipes

Here are a couple of recipes for commonly used computing facilities, which can
be easily adapted. See Cartesius for a module based setup or CCPGate for a
standard Intel installation.

* Cartesius
Load the required modules
```
module unload mpi
module load intel/2018b cmake/3.7.2
```
Setup the build:
```
cmake -H. -Bbuild -DCMAKE_Fortran_COMPILER=mpiifort
```

* CCPGate
To build with ifort set the variables for the Intel Compiler and MPI ->

If you use CSH:
```
source /software/intel/intel_2019.0.117/compilers_and_libraries_2019.1.144/linux/bin/compilervars.csh -arch intel64 -platform linux
source /software/intel/intel_2019.0.117/compilers_and_libraries_2019.0.117/linux/mpi/intel64/bin/mpivars.csh -arch intel64 -platform linux
```
If you use BASH:
```
. /software/intel/intel_2019.0.117/compilers_and_libraries_2019.1.144/linux/bin/compilervars.sh intel64
. /software/intel/intel_2019.0.117/compilers_and_libraries_2019.0.117/linux/mpi/intel64/bin/mpivars.sh intel64
```
and setup the build:
```
cmake -H. -Bbuild -DCMAKE_Fortran_COMPILER=mpiifort
```

To build with gfortran set only(!) ->
If you use CSH:
```
source /software/intel/intel_2019.0.117/impi/2019.0.117/intel64/bin/mpivars.sh -arch intel64 -platform linux
```
If you use BASH:
```
. /software/intel/intel_2019.0.117/impi/2019.0.117/intel64/bin/mpivars.sh intel64
```
and then use:
```
cmake -H. -Bbuild -DCMAKE_Fortran_COMPILER=mpif90
```
which will use LAPACK & BLAS from the Ubuntu repository. (Cmake should find
them already if none of the Intel MKL variables are set.) Combining gfortran
with the Intel MKL is possible but requires special care to work with the
compiler flag `-mcmodel=large`.

#### Documentation
CHAMP developer documentation can be generated using [Doxygen](http://www.doxygen.nl/) tool. To install the package, we advise to follow the instructions at the Doxygen web page: <http://www.doxygen.nl/download.html>.

The Doxyfile file provided in CHAMP docs directory contains all the settings needed to generate the documentation. Once Doxygen is installed, at the docs folder of CHAMP simply run:
```
doxygen Doxyfile
```
Then two folders will be created, /docs/developers/html and ./docs/developers/latex, containing the documentation about modules, subroutines and functions in both html and latex formats.
