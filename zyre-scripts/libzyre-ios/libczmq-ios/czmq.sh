#!/bin/sh
# A script to download and build czmq for iOS, including arm64
# Adapted from https://raw2.github.com/seb-m/CryptoPill/master/libsodium.sh

set -x
set -e
git clone --quiet --depth 1 https://github.com/zeromq/czmq

LIBNAME="libczmq.a"
ROOTDIR=`pwd`

#libsodium
LIBZMQ_DIST="${ROOTDIR}/libzmq-ios/libzmq_dist/"
echo "Buliding dependency libzmq..."
cd libzmq-ios
bash libzmq.sh
cd $ROOTDIR

ARCHS=${ARCHS:-"armv7 armv7s arm64 i386 x86_64"}
DEVELOPER=$(xcode-select -print-path)
LIPO=$(xcrun -sdk iphoneos -find lipo)
#LIPO=lipo
# Script's directory
SCRIPTDIR=$( (cd -P $(dirname $0) && pwd) )
# libczmq root directory
LIBDIR="czmq"
mkdir -p $LIBDIR
LIBDIR=$( (cd "${LIBDIR}"  && pwd) )
# Destination directory for build and install
DSTDIR=${SCRIPTDIR}
BUILDDIR="${DSTDIR}/libczmq_build"
DISTDIR="${DSTDIR}/libczmq_dist"
DISTLIBDIR="${DISTDIR}/lib"
TARNAME="czmq-3.0.1"
TARFILE=${TARNAME}.tar.gz
TARURL=http://download.zeromq.org/$TARFILE

# http://libwebp.webm.googlecode.com/git/iosbuild.sh
# Extract the latest SDK version from the final field of the form: iphoneosX.Y
SDK=$(xcodebuild -showsdks \
| grep iphoneos | sort | tail -n 1 | awk '{print substr($NF, 9)}'
)

OTHER_LDFLAGS=""
OTHER_CFLAGS="-Os -Qunused-arguments"
OTHER_CPPFLAGS="-Os -I${LIBZMQ_DIST}/include"
OTHER_CXXFLAGS="-Os"

# Cleanup
if [ -d $BUILDDIR ]
then
rm -rf $BUILDDIR
fi
if [ -d $DISTDIR ]
then
rm -rf $DISTDIR
fi
mkdir -p $BUILDDIR $DISTDIR

# Generate autoconf files
#cd ${LIBDIR}
cd ${LIBDIR}; ./autogen.sh

# Iterate over archs and compile static libs
for ARCH in $ARCHS
do
BUILDARCHDIR="$BUILDDIR/$ARCH"
mkdir -p ${BUILDARCHDIR}

case ${ARCH} in
armv7)
PLATFORM="iPhoneOS"
HOST="${ARCH}-apple-darwin"
export BASEDIR="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
export ISDKROOT="${BASEDIR}/SDKs/${PLATFORM}${SDK}.sdk"
export CXXFLAGS="${OTHER_CXXFLAGS}"
export CPPFLAGS="-arch ${ARCH} -isysroot ${ISDKROOT} ${OTHER_CPPFLAGS}"
export LDFLAGS="-arch ${ARCH} -isysroot ${ISDKROOT} ${OTHER_LDFLAGS}"
;;
armv7s)
PLATFORM="iPhoneOS"
HOST="${ARCH}-apple-darwin"
export BASEDIR="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
export ISDKROOT="${BASEDIR}/SDKs/${PLATFORM}${SDK}.sdk"
export CXXFLAGS="${OTHER_CXXFLAGS}"
export CPPFLAGS="-arch ${ARCH} -isysroot ${ISDKROOT} ${OTHER_CPPFLAGS}"
export LDFLAGS="-arch ${ARCH} -isysroot ${ISDKROOT} ${OTHER_LDFLAGS}"
;;
arm64)
PLATFORM="iPhoneOS"
HOST="arm-apple-darwin"
export BASEDIR="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
export ISDKROOT="${BASEDIR}/SDKs/${PLATFORM}${SDK}.sdk"
export CXXFLAGS="${OTHER_CXXFLAGS}"
export CPPFLAGS="-arch ${ARCH} -isysroot ${ISDKROOT} ${OTHER_CPPFLAGS}"
export LDFLAGS="-arch ${ARCH} -isysroot ${ISDKROOT} ${OTHER_LDFLAGS}"
;;
i386)
PLATFORM="iPhoneSimulator"
HOST="${ARCH}-apple-darwin"
export BASEDIR="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
export ISDKROOT="${BASEDIR}/SDKs/${PLATFORM}${SDK}.sdk"
export CXXFLAGS="${OTHER_CXXFLAGS}"
export CPPFLAGS="-m32 -arch ${ARCH} -isysroot ${ISDKROOT} -miphoneos-version-min=${SDK} ${OTHER_CPPFLAGS}"
export LDFLAGS="-m32 -arch ${ARCH} ${OTHER_LDFLAGS}"
;;
x86_64)
PLATFORM="iPhoneSimulator"
HOST="${ARCH}-apple-darwin"
export BASEDIR="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
export ISDKROOT="${BASEDIR}/SDKs/${PLATFORM}${SDK}.sdk"
export CXXFLAGS="${OTHER_CXXFLAGS}"
export CPPFLAGS="-arch ${ARCH} -isysroot ${ISDKROOT} -miphoneos-version-min=${SDK} ${OTHER_CPPFLAGS}"
export LDFLAGS="-arch ${ARCH} ${OTHER_LDFLAGS}"
echo "LDFLAGS $LDFLAGS"
;;
*)
echo "Unsupported architecture ${ARCH}"
exit 1
;;
esac

export PATH="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin:${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/sbin:$PATH"
export PKG_CONFIG_PATH="${ROOTDIR}/libzmq-ios/libzmq_build/${ARCH}/lib/pkgconfig/"
echo "Configuring for ${ARCH}..."
set +e
cd ${LIBDIR} && make distclean
set -e
${LIBDIR}/configure \
--prefix=${BUILDARCHDIR} \
--disable-shared \
--enable-static \
--host=${HOST}

echo "Building ${LIBNAME} for ${ARCH}..."
cd ${LIBDIR}

make -j8 V=0
make install

LIBLIST+="${BUILDARCHDIR}/lib/${LIBNAME} "
done

# Copy headers and generate a single fat library file
mkdir -p ${DISTLIBDIR}
${LIPO} -create ${LIBLIST} -output ${DISTLIBDIR}/${LIBNAME}
for ARCH in $ARCHS
do
cp -R $BUILDDIR/$ARCH/include ${DISTDIR}
break
done

# Cleanup
#rm -rf ${BUILDDIR}
