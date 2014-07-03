#!/bin/bash

THISDIR=${PWD}

EV4_BASE=$THISDIR


clean()
{
   echo "Removing old RELEASE.locals"
   find . -name RELEASE.local -exec rm {} \; 
   exit 0
}


check_shell_vars()
{
    if [ -z "${EPICS_BASE}" ]; then
        echo "EPICS_BASE unspecified." 
        exit 2       
    fi

    if [ ! -d "${EPICS_BASE}" ]; then
        echo "EPICS_BASE (${EPICS_BASE}) does not exist."
        exit 2
    fi

    if [ ! -f "${EPICS_BASE}/include/epicsVersion.h" ]; then
        echo "EPICS_BASE version file (${EPICS_BASE}/include/epicsVersion.h) does not exist."
        echo "Not a valid EPICS installation."
        exit 2
    fi

    if [ ! -z "${ARCHIVER_DIR}" ] && [ ! -d ${ARCHIVER_DIR} ]; then
        echo "ARCHIVER_DIR specified (${ARCHIVER_DIR}), but does not exist."
        exit 2
    fi

    if [ ! -d ${ARCHIVER_DIR}/include ]; then
        echo "${ARCHIVER_DIR}/include does not exist."
        echo "Not a valid channel archiver or channel archiver has not been built."
        exit 2
    fi
}


start_common()
{
    echo "configuring ..."
    echo "EPICS_BASE =  ${EPICS_BASE}"
    echo "ARCHIVER_DIR = ${ARCHIVER_DIR}"
    check_shell_vars
}


top_level()
{
    echo "EV4_BASE=${EV4_BASE}" > RELEASE.local
    echo "PVDATABASE=\$(EV4_BASE)/pvDatabaseCPP" >> RELEASE.local
    echo "PVASRV=\$(EV4_BASE)/pvaSrv" >> RELEASE.local
    echo "PVACCESS=\$(EV4_BASE)/pvAccessCPP" >> RELEASE.local
    echo "PVDATA=\$(EV4_BASE)/pvDataCPP" >> RELEASE.local
    echo "PVCOMMON=\$(EV4_BASE)/pvCommonCPP" >> RELEASE.local
    if [ -d ${ARCHIVER_DIR} ]; then
        echo "ARCHIVER=${ARCHIVER_DIR}" >> RELEASE.local
    fi
    echo "EPICS_BASE=${EPICS_BASE}" >> RELEASE.local
    echo "RELEASE.local file created"
}

pvcommon()
{
    if [ -e pvCommonCPP/configure ]; then
        pushd pvCommonCPP/configure
        echo "EPICS_BASE=${EPICS_BASE}" > RELEASE.local
        popd
    else
        echo "Skipping pvCommonCPP/configure - doesn't exist" 
    fi
}

pvdata()
{
    if [ -e pvDataCPP/configure ]; then
        echo "Making config files for pvCommonCPP" 
        pushd pvDataCPP/configure
        echo "EV4_BASE=${EV4_BASE}" > RELEASE.local
        echo "PVCOMMON=\$(EV4_BASE)/pvCommonCPP" >> RELEASE.local
        echo "EPICS_BASE=${EPICS_BASE}" >> RELEASE.local   
        popd
    else
        echo "Skipping pvDataCPP: configure - doesn't exist" 
    fi
}

pvaccess()
{
    if [ -e pvAccessCPP/configure ]; then
        echo "Making config files for pvAccessCPP" 
        pushd pvAccessCPP/configure
        echo "EV4_BASE=${EV4_BASE}" > RELEASE.local
        echo "PVDATA=\$(EV4_BASE)/pvDataCPP" >> RELEASE.local
        echo "PVCOMMON=\$(EV4_BASE)/pvCommonCPP" >> RELEASE.local
        echo "EPICS_BASE=${EPICS_BASE}" >> RELEASE.local
        popd
    else
        echo "Skipping pvAccessCPP: configure - doesn't exist" 
    fi
}

pvasrv()
{
    if [ -e pvaSrv/configure ]; then
        echo "Making config files for pvaSrv" 
        pushd pvaSrv/configure
        echo "EV4_BASE=${EV4_BASE}" > RELEASE.local
        echo "PVACCESS=\$(EV4_BASE)/pvAccessCPP" >> RELEASE.local
        echo "PVDATA=\$(EV4_BASE)/pvDataCPP" >> RELEASE.local
        echo "PVCOMMON=\$(EV4_BASE)/pvCommonCPP" >> RELEASE.local
        echo "EPICS_BASE=${EPICS_BASE}" >> RELEASE.local
        popd
    else
        echo "Skipping pvaSrv: configure doesn't exist" 
    fi
}

pvDatabase()
{
    if [ -e pvDatabaseCPP/configure ]; then
        echo "Making config files for pvDatabaseCPP" 
        pushd pvDatabaseCPP/configure
        echo "EV4_BASE=${EV4_BASE}" > RELEASE.local
        echo "PVASRV=\$(EV4_BASE)/pvaSrv" >> RELEASE.local
        echo "PVACCESS=\$(EV4_BASE)/pvAccessCPP" >> RELEASE.local
        echo "PVDATA=\$(EV4_BASE)/pvDataCPP" >> RELEASE.local
        echo "PVCOMMON=\$(EV4_BASE)/pvCommonCPP" >> RELEASE.local
        echo "EPICS_BASE=${EPICS_BASE}" >> RELEASE.local
        popd
    else
        echo "Skipping pvDatabaseCPP: configure doesn't exist" 
    fi
}


helloWorld()
{
    if [ -e exampleCPP/HelloWorld/configure ]; then
        echo "Making config files for exampleCPP/HelloWorld" 
        pushd exampleCPP/HelloWorld/configure
        echo "EV4_BASE=${EV4_BASE}" > RELEASE.local
        echo "PVACCESS=\$(EV4_BASE)/pvAccessCPP" >> RELEASE.local
        echo "PVDATA=\$(EV4_BASE)/pvDataCPP" >> RELEASE.local
        echo "PVCOMMON=\$(EV4_BASE)/pvCommonCPP" >> RELEASE.local
        echo "EPICS_BASE=${EPICS_BASE}" >> RELEASE.local
        popd
    else
        echo "Skipping exampleCPP/HelloWorld: configure doesn't exist" 
    fi
}

archiverService()
{
    if [ -e exampleCPP/ChannelArchiverService/configure ]; then
        echo "Making files for exampleCPP/ChannelArchiverService"
        if [ -z "${ARCHIVER_DIR}" ] ]; then
            echo "ARCHIVER_DIR not specified, but required for ChannelArchiverService."
            echo "Skipping making config."
            exit 2
        else 
            pushd exampleCPP/ChannelArchiverService/configure
            echo "EV4_BASE=${EV4_BASE}" > RELEASE.local
            echo "PVACCESS=\$(EV4_BASE)/pvAccessCPP" >> RELEASE.local
            echo "PVDATA=\$(EV4_BASE)/pvDataCPP" >> RELEASE.local
            echo "PVCOMMON=\$(EV4_BASE)/pvCommonCPP" >> RELEASE.local
            echo "ARCHIVER=${ARCHIVER_DIR}" >> RELEASE.local
            echo "EPICS_BASE=${EPICS_BASE}" >> RELEASE.local
            popd
        fi
    else
        echo "Skipping exampleCPP/ChannelArchiverService: configure doesn't exist" 
    fi
}



if [ "$1" = "clean" ]; then
    clean
fi


if [ "$1" = "" ]; then
    start_common
    top_level
    echo "Configuration successful"
    exit 0
fi


if [ "$1" = "all" ]; then
    start_common
    pvcommon
    pvdata
    pvaccess
    pvasrv
    pvDatabase
    helloWorld
    archiverService
    exit 0
fi

echo "Unknown option $1"
exit 1




