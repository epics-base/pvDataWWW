#!/bin/bash
#!-*- sh -*-
# 
#      makereleaseCPP is a bash source script to manage the release of source files and 
#      associated deliverables for a version tagged release of the CPP implementation 
#      of EPICS v4. 
#
# Usage:     
#      ./makereleaseCPP.sh -n <releaseName> [-f] [-V]
# 
#      Once all of the V4 core C++ modules have been tagged
#      (pvDataCPP, pvAccessCPP etc), as described in release.html,
#      hg checkout pvDataWWW. Edit pvDataWWW/configure/RELEASE_VERSIONS 
#      to define the modules of the release and their Mercurial (hg) tags. 
#
#      For examples see Usage function below.
#
#      A user should unpack the resulting tar.gz with, for instance:
#            tar zxvf EPICS-CPP-4.4.0.tar.gz
#
# Ref: http://epics-pvdata.sourceforge.net/release.html
#
# ----------------------------------------------------------------------------
#
# Auth: Dave Hickin
# Mod: 22-Oct-2013, Greg White (greg@slac.stanford.edu) 
#       Fixed awk command for matching "full releases", eg EPICS-java-4.3.0 rather 
#       than those with suffix. The old one matched also suffix 
#       release lines, so modules could have been included twice.
#       
# ============================================================================


function usage { 
echo "
   makereleaseCPP.sh creates the tar file of the CPP modules, together with
   other relevant files, of an EPICS V4 release. 

   Usage:

       makereleaseCPP.sh -n <releaseName> [-f ] [-V] 

       -n <releaseName>      The string identifying the release. This is the
                             key used to search RELEASE_VERSIONS to find the
                             modules in the release.

       -V                    Uses the specified release versions file
                             RELEASE_VERSIONS in the pvDataWWW/scripts dir and
                             the README file in pvDataWWW/mainPage of the copy
                             of pvDataWWW which contains the version of this
                             script which has been run.

       -o <outdir>           Output directory

       -f                    Removes any files left from running the script
                             previously.

   Examples:

         $ makereleaseCPP.sh -V -n EPICS-CPP-4.3.0-pre1

       In this example, makereleaseCPP.sh packages a tar for a release named
       EPICS-CPP-4.3.0-pre1, as specified in the RELEASE_VERSIONS file in the 
       copy of pvDataWWW which contains the version of this script which has
       been executed.
       It will first clone the files it finds in the mercurial repo and
       package them into a tar file along with the copy of README found in the
       copy of pvDataWWW

         $ makereleaseCPP.sh -n EPICS-CPP-4.3.0-pre1

       This time makereleaseCPP.sh packages a tar for the release
       EPICS-CPP-4.3.0-pre1, as specified in the RELEASE_VERSIONS file it 
       finds on the web (see URL in source of this script).
       Again it clones the files and adds the README from the web.

"
}

function Exit {
    exit $1
}

releaseName= 
localreleaseinfo=0
force=0

while getopts hfu:Vn: opt; do
   case "$opt" in
       h) usage; Exit 0 ;;
       f) force=1 ;;
       V) localreleaseinfo=1 ;;
       n) releaseName=${OPTARG} ;; 
       o) outdir="${OPTARG}" ;;
       *) echo "Unknown Argument, see makereleaseCPP.sh -h"; Exit 1;;
   esac
done
shift $((OPTIND-1));

set -e -x

declare -a modulesa

readme_name=README_CPP.md
release_notes_name=RELEASE_NOTES_CPP.md

# Remote location of the file which defines the versions of each package going into
# tar file for the given release.
RELEASE_VERSIONS_URL=\
https://raw.githubusercontent.com/epics-base/pvDataWWW/master/scripts/RELEASE_VERSIONS

# Remote location of the README file
README_URL=\
https://raw.githubusercontent.com/epics-base/pvDataWWW/master/scripts/${readme_name}

# Remote location of the release notes
RELEASE_NOTES_URL=\
https://raw.githubusercontent.com/epics-base/pvDataWWW/master/scripts/${release_notes_name}

# Remote location of the Makefile
MAKEFILE_URL=\
https://raw.githubusercontent.com/epics-base/pvDataWWW/master/scripts/Makefile

# Remote location of the configuration script
CONFIG_SCRIPT_URL=\
https://raw.githubusercontent.com/epics-base/pvDataWWW/master/scripts/configure.sh

# Remote location of the CONFIG(_SITE).local
CONFIG_LOCAL_URL=\
https://raw.githubusercontent.com/epics-base/pvDataWWW/master/scripts/CONFIG_SITE.local

# Remote location of the RELEASE.local file
RELEASE_LOCAL_URL=\
https://raw.githubusercontent.com/epics-base/pvDataWWW/master/scripts/RELEASE.local

file=$0
scriptdir=$( readlink -f "$( dirname "${file}" )" )



[ "${outdir}" ] || outdir="${PWD}/${releaseName}"

if [ -z ${releaseName} ]; then
    echo "The release name is a required argument, (specify with -n)"
    echo "See makereleaseCPP.sh -h"
    Exit 2
fi

workdir=`mktemp -d`

# automatic cleanup of temp working dir
trap "rm -rf ${workdir};echo cleanup ${workdir}" INT QUIT TERM EXIT

install -d "${workdir}/tar"
install -d "${workdir}/links"
install -d "${workdir}/download" && cd "${workdir}/download"

tarfile="${releaseName}.tar.gz"


# Check the directory whose contents we'll tar doesn't already exist
if [ -e ${outdir} ]; then
    if [ ${force} -eq 1 ]; then
        rm -rf ${outdir}
    else
	    echo "${outdir} already exists. Remove/move before trying again or use
the force option (-f)."
        Exit 4
    fi
fi


# Check the tar doesn't exit either
if [ -e ${tarfile} ]; then
    if [ ${force} -eq 1 ]; then
        rm -rf ${tarfile}
    else
	    echo "${tarfile} already exists. Remove/move before trying again or use
the force option (-f)."
        Exit 5
    fi
fi

# Locate the RELEASE_VERSIONS file, to tell which modules are in the release,
# and the README file to be added to the bundle
#
config_script_name=configure.sh
if [ ${localreleaseinfo} -eq 1 ]; then
    release_versions_pathname=${scriptdir}/RELEASE_VERSIONS
    release_notes_pathname=${scriptdir}/${release_notes_name}
    readme_pathname=${scriptdir}/${readme_name}
    makefile_pathname=${scriptdir}/Makefile
    config_script_pathname=${scriptdir}/${config_script_name}
    config_site_local_pathname=${scriptdir}/CONFIG_SITE.local
    release_local_pathname=${scriptdir}/RELEASE.local
else
    # Get the remote version file.
    # Delete the existing file first if it's already there.
    if [ -e RELEASE_VERSIONS ]; then
        rm -rf RELEASE_VERSIONS
    fi
    wget ${RELEASE_VERSIONS_URL}
    release_versions_pathname=${PWD}/RELEASE_VERSIONS

    # Get the remote readme file.
    # Delete the existing file first if it's already there.
    if [ -e ${readme_name} ]; then
        rm -rf ${readme_name}
    fi

    wget ${README_URL}
    readme_pathname=${PWD}/${readme_name}

    # Get the remote version file.
    # Delete the existing file first if it's already there.
    if [ -e RELEASE_VERSIONS ]; then
        rm -rf RELEASE_VERSIONS
    fi
    wget ${RELEASE_VERSIONS_URL}
    release_versions_pathname=${PWD}/RELEASE_VERSIONS

    # Get the remote release notes file.
    # Delete the existing file first if it's already there.
    if [ -e ${release_notes_name} ]; then
        rm -rf ${release_notes_name}
    fi
    wget ${RELEASE_NOTES_URL}
    release_notes_pathname=${PWD}/${release_notes_name}

    # Get the remote readme file.
    # Delete the existing file first if it's already there.
    readme_name=README_CPP.md
    if [ -e ${readme_name} ]; then
        rm -rf ${readme_name}
    fi
    wget ${README_URL}
    config_script_pathname=${PWD}/${readme_name}

    # Get the remote Makefile.
    # Delete the existing file first if it's already there.
    if [ -e Makefile ]; then
        rm -rf Makefile
    fi
    wget ${MAKEFILE_URL}
    makefile_pathname=${PWD}/Makefile

    # Get the remote config script file.
    # Delete the existing file first if it's already there.
    if [ -e configure.sh ]; then
        rm -rf configure.sh
    fi
    wget ${CONFIG_SCRIPT_URL}
    config_script_pathname=${PWD}/${config_script_name}

    if [ -e CONFIG_SITE.local ]; then
        rm -rf CONFIG_SITE.local
    fi
    wget ${CONFIG_LOCAL_URL}
    config_site_local_pathname=${PWD}/CONFIG_SITE.local

    # Get the RELEASE.local.
    # Delete the existing file first if it's already there.
    if [ -e RELEASE.local ]; then
        rm -rf RELEASE.local
    fi
    wget ${RELEASE_LOCAL_URL}
    release_local_pathname=${PWD}/RELEASE.local
fi

if [ ! -f ${release_versions_pathname} ]; then
    echo "Failed to locate the release versions file ${release_versions_pathname}"
    Exit 6
fi

if [ ! -f ${readme_pathname} ]; then
    echo "Failed to locate the README file ${readme_pathname}"
    Exit 6
fi

if [ ! -f ${release_notes_pathname} ]; then
    echo "Failed to locate the release versions file${release_notes_pathname}"
    Exit 6
fi

if [ ! -f ${makefile_pathname} ]; then
    echo "Failed to locate the Makefile file ${makefile_pathname}"
    Exit 6
fi

if [ ! -f ${config_script_pathname} ]; then
    echo "Failed to locate the config script file ${config_script_pathname}"
    Exit 6
fi

if [ ! -f ${config_site_local_pathname} ]; then
    echo "Failed to locate the CONFIG_SITE.local file ${config_site_local_pathname}"
    Exit 6
fi

if [ ! -f ${release_local_pathname} ]; then
    echo "Failed to locate the RELEASE.local file ${release_local_pathname}"
    Exit 6
fi

# Construct fully qualified pathname of RELEASE_VERSIONS file
file=$release_versions_pathname
release_versions_pathname=$( readlink -f "$( dirname "$file" )" )/$( basename "$file" )

# Construct fully qualified pathname of RELEASE_NOTES file
file=$release_notes_pathname
release_notes_pathname=$( readlink -f "$( dirname "$file" )" )/$( basename "$file" )

# Construct fully qualified pathname of REAMDE file
file=$readme_pathname
readme_pathname=$( readlink -f "$( dirname "$file" )" )/$( basename "$file" )

# Construct fully qualified pathname of Makefile file
file=$makefile_pathname
makefile_pathname=$( readlink -f "$( dirname "$file" )" )/$( basename "$file" )

# Construct fully qualified pathname of configure script file
file=$config_script_pathname
config_script_pathname=$( readlink -f "$( dirname "$file" )" )/$( basename "$file" )

# Construct fully qualified pathname of CONFIG.local file
file=$config_site_local_pathname
config_site_local_pathname=$( readlink -f "$( dirname "$file" )" )/$( basename "$file" )

# Construct fully qualified pathname of RELEASE.local file
file=$release_local_pathname
release_local_pathname=$( readlink -f "$( dirname "$file" )" )/$( basename "$file" )


# Read the repos and versions that the release tar must be composed of from the
# RELEASE_VERSIONS file.
modulesa=(`awk -v relname=${releaseName} 'BEGIN {relname="^" relname "$"} $1 ~ relname {print $2}' < $release_versions_pathname`)


# Check we got at least 1 module.
if [ ${#modulesa[@]} -lt 1 ]; then
    echo "Release versions"
    cat $release_versions_pathname
    echo "Failed to find modules for release ${releaseName}"
    Exit 7
fi

echo ${releaseName} is composed of ${modulesa[*]}

tags_filename="${workdir}/tar/RELEASE_IDS"
file=$tags_filename
tags_pathname=$( readlink -f "$( dirname "$file" )" )/$( basename "$file" )
echo "# Module IDs for release ${releaseName}"   > $tags_pathname
echo "# module tag commit_id reference" >> $tags_pathname

for modulei in ${modulesa[*]}
do
    tag=`awk -v relname=${releaseName} -v modulename=${modulei} \
          'BEGIN {relname="^" relname "$"} $1 ~ relname && $2 ~ modulename {print $3}' < $release_versions_pathname`

    if [ $? -ne 0 ]; then
	    echo "Could not get module version for ${modulei}, exiting"
	    Exit 8
    fi

    echo "Adding ${modulei} ${tag} to ${releaseName} tar directory"

    install -d "${workdir}/tar/${modulei}"
    # clone module from sourceforge
    curl "https://codeload.github.com/epics-base/${modulei}/tar.gz/${tag}" \
    | tar -C "${workdir}/tar/${modulei}" --strip-components=1 -xz

    tag_id=`git ls-remote https://github.com/epics-base/${modulei}.git ${tag}`
    echo "${modulei} ${tag} ${tag_id}" >> ${tags_pathname}

    ln -s ../${modulei}/${tag} ${workdir}/links/${modulei}
done


# Add RELEASE_NOTES, README, Makefile and configure.sh to the bundle
echo Adding RELEASE_VERSIONS, README, Makefile and configure.sh
cp $release_notes_pathname "${workdir}/tar/RELEASE_NOTES.md"
cp $readme_pathname "${workdir}/tar/README.md"
cp $makefile_pathname "${workdir}/tar/"
cp $config_script_pathname "${workdir}/tar/"
cp $config_site_local_pathname "${workdir}/tar/"
cp $release_local_pathname "${workdir}/tar/ExampleRelease.local"
chmod +x "${workdir}/tar/${config_script_name}"


# Create tarball and documentation links
mv ${workdir}/tar ${workdir}/${releaseName}
echo "Tarring ${workdir}/${releaseName} to ${outdir}/${tarfile}"
install -d "${outdir}"
tar -C "${workdir}" -czf "${outdir}/${tarfile}" "${releaseName}"
echo "Copying documentation links to ${outdir}/links"
cp -a "${workdir}/links" "${outdir}"
