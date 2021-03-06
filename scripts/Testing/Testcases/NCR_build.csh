#!/bin/csh -f
setenv CIMEROOT `./xmlquery CIMEROOT    -value`

./Tools/check_lockedfiles || exit -1

# NOTE - Are assumming that are already in $CASEROOT here
set CASE        = `./xmlquery CASE     -value`
set EXEROOT     = `./xmlquery EXEROOT  -value`

# Reset all previous env_mach_pes settings
if ( -e env_mach_pes.xml.1 )  then
  cp -f env_mach_pes.xml.1 env_mach_pes.xml
else
  cp -f env_mach_pes.xml env_mach_pes.xml.1
endif

./case.setup -clean -testmode
./case.setup 

cp -f env_mach_pes.xml env_mach_pes.xml.1
cp -f env_mach_pes.xml LockedFiles/env_mach_pes.xml.locked
cp -f env_mach_pes.xml env_mach_pes.xml.1
cp -f env_build.xml    env_build.xml.1
 
#------------------------------------------------------------
# Set up sequential component layout for single instance for each component

./xmlchange -file env_mach_pes.xml -id NINST_ATM  -val 1
./xmlchange -file env_mach_pes.xml -id NINST_LND  -val 1
./xmlchange -file env_mach_pes.xml -id NINST_ROF  -val 1
./xmlchange -file env_mach_pes.xml -id NINST_WAV  -val 1
./xmlchange -file env_mach_pes.xml -id NINST_OCN  -val 1
./xmlchange -file env_mach_pes.xml -id NINST_ICE  -val 1
./xmlchange -file env_mach_pes.xml -id NINST_GLC  -val 1

./xmlchange -file env_mach_pes.xml -id ROOTPE_ATM  -val 0
./xmlchange -file env_mach_pes.xml -id ROOTPE_LND  -val 0
./xmlchange -file env_mach_pes.xml -id ROOTPE_ROF  -val 0
./xmlchange -file env_mach_pes.xml -id ROOTPE_WAV  -val 0
./xmlchange -file env_mach_pes.xml -id ROOTPE_OCN  -val 0
./xmlchange -file env_mach_pes.xml -id ROOTPE_ICE  -val 0
./xmlchange -file env_mach_pes.xml -id ROOTPE_GLC  -val 0
./xmlchange -file env_mach_pes.xml -id ROOTPE_CPL  -val 0

set NTASKS_ATM  = `./xmlquery NTASKS_ATM  -value`
set NTASKS_LND  = `./xmlquery NTASKS_LND  -value`
set NTASKS_ROF  = `./xmlquery NTASKS_ROF  -value`
set NTASKS_WAV  = `./xmlquery NTASKS_WAV  -value`
set NTASKS_OCN  = `./xmlquery NTASKS_OCN  -value`
set NTASKS_ICE  = `./xmlquery NTASKS_ICE  -value`
set NTASKS_GLC  = `./xmlquery NTASKS_GLC  -value`
set NTASKS_CPL  = `./xmlquery NTASKS_CPL  -value`

 if ( $NTASKS_ATM > 1 ) then
   @ ntask = $NTASKS_ATM / 2
   ./xmlchange -file env_mach_pes.xml -id NTASKS_ATM  -val $ntask
 endif
 if ( $NTASKS_LND > 1 ) then
   @ ntask = $NTASKS_LND / 2
   ./xmlchange -file env_mach_pes.xml -id NTASKS_LND  -val $ntask
 endif
 if ( $NTASKS_ROF > 1 ) then
   @ ntask = $NTASKS_ROF / 2
   ./xmlchange -file env_mach_pes.xml -id NTASKS_ROF  -val $ntask
 endif
 if ( $NTASKS_WAV > 1 ) then
   @ ntask = $NTASKS_WAV / 2
   ./xmlchange -file env_mach_pes.xml -id NTASKS_WAV  -val $ntask
 endif
 if ( $NTASKS_OCN > 1 ) then
   @ ntask = $NTASKS_OCN / 2
   ./xmlchange -file env_mach_pes.xml -id NTASKS_OCN  -val $ntask
 endif
 if ( $NTASKS_ICE > 1 ) then
   @ ntask = $NTASKS_ICE / 2
   ./xmlchange -file env_mach_pes.xml -id NTASKS_ICE  -val $ntask
 endif
 if ( $NTASKS_GLC > 1 ) then
   @ ntask = $NTASKS_GLC / 2
   ./xmlchange -file env_mach_pes.xml -id NTASKS_GLC  -val $ntask
 endif

./xmlchange -file env_build.xml -id NINST_BUILD -val 0

./case.setup -clean -testmode
./case.setup

./case.clean_build 

./case.build -testmode
if ($status != 0) then
   echo "Error: build for single instance failed" >! ./TestStatus
   echo "CFAIL $CASE" > ./TestStatus
   exit -1    
endif 

mv -f $EXEROOT/cesm.exe $EXEROOT/cesm.exe.1  || exit -9
cp -f env_mach_pes.xml   env_mach_pes.xml.1
cp -f env_build.xml       env_build.xml.1


#----------------------------------------------------------------------
# Set up concurrent component layout for 2 instances for each component
#----------------------------------------------------------------------

./xmlchange -file env_mach_pes.xml -id NINST_ATM  -val 2
./xmlchange -file env_mach_pes.xml -id NINST_LND  -val 2
./xmlchange -file env_mach_pes.xml -id NINST_ROF  -val 2
./xmlchange -file env_mach_pes.xml -id NINST_WAV  -val 2
./xmlchange -file env_mach_pes.xml -id NINST_OCN  -val 2
./xmlchange -file env_mach_pes.xml -id NINST_ICE  -val 2
./xmlchange -file env_mach_pes.xml -id NINST_GLC  -val 2

set NTASKS_ATM  = `./xmlquery NTASKS_ATM	-value`
set NTASKS_LND  = `./xmlquery NTASKS_LND	-value`
set NTASKS_ROF  = `./xmlquery NTASKS_ROF	-value`
set NTASKS_WAV  = `./xmlquery NTASKS_WAV	-value`
set NTASKS_OCN  = `./xmlquery NTASKS_OCN	-value`
set NTASKS_ICE  = `./xmlquery NTASKS_ICE	-value`
set NTASKS_GLC  = `./xmlquery NTASKS_GLC	-value`
set NTASKS_CPL  = `./xmlquery NTASKS_CPL	-value`

@ rootp = 0
./xmlchange -file env_mach_pes.xml -id ROOTPE_CPL  -val $rootp
@ ntask = $NTASKS_ATM * 2
@ rootp = $rootp + $ntask
./xmlchange -file env_mach_pes.xml -id NTASKS_ATM  -val $ntask
./xmlchange -file env_mach_pes.xml -id ROOTPE_ATM  -val $rootp
@ ntask = $NTASKS_LND * 2
@ rootp = $rootp + $ntask
./xmlchange -file env_mach_pes.xml -id NTASKS_LND  -val $ntask
./xmlchange -file env_mach_pes.xml -id ROOTPE_LND  -val $rootp
@ ntask = $NTASKS_ROF * 2
@ rootp = $rootp + $ntask
./xmlchange -file env_mach_pes.xml -id NTASKS_ROF  -val $ntask
./xmlchange -file env_mach_pes.xml -id ROOTPE_ROF  -val $rootp
@ ntask = $NTASKS_WAV * 2
@ rootp = $rootp + $ntask
./xmlchange -file env_mach_pes.xml -id NTASKS_WAV  -val $ntask
./xmlchange -file env_mach_pes.xml -id ROOTPE_WAV  -val $rootp
@ ntask = $NTASKS_OCN * 2
@ rootp = $rootp + $ntask
./xmlchange -file env_mach_pes.xml -id NTASKS_OCN  -val $ntask
./xmlchange -file env_mach_pes.xml -id ROOTPE_OCN  -val $rootp
@ ntask = $NTASKS_ICE * 2
@ rootp = $rootp + $ntask
./xmlchange -file env_mach_pes.xml -id NTASKS_ICE  -val $ntask
./xmlchange -file env_mach_pes.xml -id ROOTPE_ICE  -val $rootp
@ ntask = $NTASKS_GLC * 2
@ rootp = $rootp + $ntask

./xmlchange -file env_mach_pes.xml -id NTASKS_GLC  -val $ntask
./xmlchange -file env_mach_pes.xml -id ROOTPE_GLC  -val $rootp
./xmlchange -file env_build.xml    -id NINST_BUILD -val 0

./case.setup -clean -testmode
./case.setup

./case.cleanbuild

./case.build -testmode
if ($status != 0) then
   echo "Error: build for single instance failed" >! ./TestStatus
   echo "CFAIL $CASE" > ./TestStatus
   exit -1    
endif 

mv -f $EXEROOT/cesm.exe $EXEROOT/cesm.exe.2  || exit -9
cp -f env_mach_pes.xml   env_mach_pes.xml.2
cp -f env_build.xml      env_build.xml.2

