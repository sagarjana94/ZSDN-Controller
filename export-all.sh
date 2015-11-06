#!/bin/bash

CppModulesPath="modules/cpp"
JavaModulesPath="modules/java"



# Help output
function printHelp {
    echo "Options:"    
    echo "   -m [moduleset] (mandatory) specify module set to build"    
    for i in "${ModuleSets[@]}"
    do
        echo "                  [moduleset] $i"
    done
    echo "   -b [target]>   (optional) set build target, otherwise system default";
    echo "                  [target] pi build for Raspberry Pi ARM"
}


# Parse Parameters
BuildParams=" -c"
BuildTarget="default"

while getopts m:hb: flag; do
  case $flag in
    m)
        BuildParams="${BuildParams} -m ${OPTARG}"
        ;;
    h)
        echo "Script to export ZSDN modules"
        echo
        printHelp
        exit 0
        ;;
    b)
        echo "-b build target: $OPTARG"
        BuildParams="${BuildParams} -b ${OPTARG}"
        BuildTarget=$OPTARG
        ;;
    ?)
        echo "!!Unknown parameter: $flag" 
        ;;
  esac
done


echo "### Start building selected modules"
if ./build-all.sh${BuildParams}; then
	echo "# Build modules success"
else
	result=$?
	echo "!! Failed to build modules"
	exit ${result}
fi


BuildFolder="build/modules/$BuildTarget" 
BuildName="zsdn_${BuildTarget}-target"
ExportFolder=".temp/export/${BuildName}" 


# Have an empty export temp folder
if [ -d "$ExportFolder" ]; then
	rm -r $ExportFolder
fi
mkdir -p $ExportFolder
echo "# Created temporary export folder $ExportFolder"


# Copy modules
cp ${BuildFolder}/. ${ExportFolder}/ -R
echo "# Copied modules"

# Copy depencencies
# TODO Adapt for pi build?
mkdir -p ${ExportFolder}/lib
cp dependencies/lib*/*.so* ${ExportFolder}/lib
cp ZMF/dependencies/lib*/*.so* ${ExportFolder}/lib
cp ZMF/lib*/*.so* ${ExportFolder}/lib
echo "# Copied dependencies"


# TODO Library path script?
# TODO Run all script?


# Copy config folder
cp config/. ${ExportFolder}/config -R
echo "Exported config folder"


# Create export archive
cd ".temp/export/"
exportTar="${BuildName}.tar.gz"
# TODO path in archive
echo "# Start packing export"
if tar -cvzf "$exportTar" "${BuildName}"; then
	echo "# Packing success"
else
	result=$?
	echo "!! Packing failed"
	exit ${result}
fi

# Move export tar to export folder
cd ../..
if ! [ -d "export" ]; then
	mkdir "export"
fi
mv ".temp/export/${BuildName}.tar.gz" "export/${BuildName}.tar.gz"


# Delete export temp folder
rm -r $ExportFolder
echo "# Deleted temporary folder"


echo "### Exported build to export/$exportTar"