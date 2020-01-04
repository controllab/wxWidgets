#!/bin/bash

#
# This script will generate and build  a set of directories debug-* and release* with various setup makefile.
#
if [ $# -lt 1 ]; then
	echo "usage $0 [--disable-gui] release|all|debug [ansi|unicode] [static|shared]"
	echo "E.g.: $0 release static unicode"
	echo "Default when not specified: release, static, ansi with GUI support"
	exit
fi

build="release"
buildtype="static"
chartype="ansi"
wx_opts=""
WX_VERSION=wx2812
WXVERSION=2.8.12

for arg in "$@"
do
	case "$arg" in
	--disable-gui)
		wx_opts="--disable-gui"
		;;
	release)
		build="release"
		;;
	debug)
		build="debug"
		;;
	all)
		build="ALL"
		;;
	static)
		buildtype="static"
		;;
	shared)
		buildtype="shared"
		;;
	ansi)
		chartype="ansi"
		;;
	unicode)
		chartype="unicode"
		;;
	esac
done

WX_SRC_DIR=${PWD}/../

#
# Do not forget to check your prefixs and paths
#
WX_PREFIX="/usr/local/"

function build_all {
	build_wx "debug"   "static" "ansi" 
	build_wx "debug"   "static" "unicode" 
	
	build_wx "release" "static" "ansi" 
	build_wx "release" "static" "unicode"
	build_wx "release" "shared" "ansi" 
	build_wx "release" "shared" "unicode"
}

# store the current pwd
CURPWD=${PWD}

#
# This function takes 4 arguments
# $1 "debug" or "release" for either a debug or release build
# $2 "shared" or "static" for either a shared or static build
# $3 "ANSI" or "UNICODE" for either a ansi or unicode build
function build_wx {
	cd ${WX_SRC_DIR}

	DEBUG_RELEASE_TYPE="$1"
	SHARED_STATIC_TYPE="$2"
	ANSI_UNICODE_TYPE="$3"

	OUTPUT_DIR="${WX_VERSION}-${DEBUG_RELEASE_TYPE}-${SHARED_STATIC_TYPE}"

	OPTS=${wx_opts}

	#
	# For msys add --with-msw switch
	#
	if [ ${OSTYPE} = "msys" ]; then
		OPTS="--with-msw"
	fi

	#
	# Set debug release options
	#
	if [ ${DEBUG_RELEASE_TYPE} = "debug" ]; then
		OPTS="${OPTS} --enable-debug --enable-debug_gdb"
	fi

	#
	# Set shared static options
	#
	if [ ${SHARED_STATIC_TYPE} = "static" ]; then
		OPTS="${OPTS} --disable-shared"
	fi

	#
	# Set ansi unicode options
	#
	if [ ${ANSI_UNICODE_TYPE} = "unicode" ]; then
		OPTS="${OPTS} --enable-unicode"
		OUTPUT_DIR="${OUTPUT_DIR}-unicode"
	fi

	INSTALL_DIR="${WX_PREFIX}${OUTPUT_DIR}"

	# Add the prefix dir
	OPTS="${OPTS} --prefix=${INSTALL_DIR}"

	# check if build already exists
	if [ -d "${INSTALL_DIR}" ]; then
		echo "**************************************"
		echo "Build already exists : skipping ${INSTALL_DIR}"
		echo "**************************************"
		return;
	fi

	echo "**************************************"
	echo "output directory  : " ${OUTPUT_DIR}
	echo "install directory : " ${INSTALL_DIR}
	echo "build type        : " ${DEBUG_RELEASE_TYPE}"-"${SHARED_STATIC_TYPE}-"${ANSI_UNICODE_TYPE}"
	echo "configure options : " ${OPTS}
	echo "**************************************"

	# create the output directory
	if [ ! -d "${CURPWD}/${OUTPUT_DIR}" ]; then
		mkdir -p "${CURPWD}/${OUTPUT_DIR}"
	fi

	# goto this directory
	cd "${CURPWD}/${OUTPUT_DIR}"


	echo "please wait when building, see build.log for details"

	if [ ${OSTYPE} == "msys" ]; then
		export CXXFLAGS="-fno-keep-inline-dllexport"
		SUDO=''
	else
		SUDO=sudo
	fi

	${WX_SRC_DIR}/configure ${OPTS} &>build.log && {
		make -j4 &>build.log && {
					echo Executing ${SUDO} make install
					${SUDO} make install &>build.log || echo "install failed"
		} || echo "build failed"
	} || echo "configure failed"

	cd "${CURPWD}"
}

# Perform the build
if [ ${build} = "all" ]; then
	build_all
else
	build_wx "${build}" "${buildtype}" "${chartype}" 
fi
