#!/usr/bin/env bash
set -ex

BUILD_NUMBER=$1
script_dir=$(dirname "$0")
cd ${script_dir}/..

outdir="debian"
debdir="$outdir/DEBIAN"

rm -rf $outdir
mkdir -p $outdir
mkdir -p $debdir

bindir="$outdir/usr/bin"
mkdir -p $bindir
cp resources/bin/cudasdk_examples/bandwidthTest/bandwidthTest $bindir/cuda_bandwidthTest
cp resources/bin/cudasdk_examples/deviceQuery/deviceQuery $bindir/cuda_deviceQuery
cp resources/bin/cudasdk_examples/matrixMul/matrixMul $bindir/cuda_matrixMul

cwd=`pwd`
cd $outdir
find . -type f ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf '%P ' | xargs md5sum > DEBIAN/md5sums
cd $cwd

version="1.0.0"

package="pkg-nvidia-cudasdk-examples"
maintainer="Nvidia <https://www.nvidia.com/en-us/support/>"
arch="amd64"
depends="dkms"

#date=`date -u +%Y%m%d`
#echo "date=$date"

#gitrev=`git rev-parse HEAD | cut -b 1-8`
gitrevfull=`git rev-parse HEAD`
gitrevnum=`git log --oneline | wc -l | tr -d ' '`
#echo "gitrev=$gitrev"

buildtimestamp=`date -u +%Y%m%d-%H%M%S`
hostname=`hostname`
echo "build machine=${hostname}"
echo "build time=${buildtimestamp}"
echo "gitrevfull=$gitrevfull"
echo "gitrevnum=$gitrevnum"

debian_revision="${gitrevnum}"
upstream_version="${version}"
echo "upstream_version=$upstream_version"
echo "debian_revision=$debian_revision"

packageversion="${upstream_version}-github${debian_revision}"
packagename="${package}_${packageversion}_${arch}"
echo "packagename=$packagename"
packagefile="${packagename}.deb"
echo "packagefile=$packagefile"

description="build machine=${hostname}, build time=${buildtimestamp}, git revision=${gitrevfull}"
if [ ! -z ${BUILD_NUMBER} ]; then
    echo "build number=${BUILD_NUMBER}"
    description="$description, build number=${BUILD_NUMBER}"
fi

installedsize=`du -s $outdir | awk '{print $1}'`

#for format see: https://www.debian.org/doc/debian-policy/ch-controlfields.html
cat > $debdir/control << EOF |
Section: restricted/misc
Priority: optional
Maintainer: $maintainer
Version: $packageversion
Package: $package
Architecture: $arch
Pre-Depends: virt-what
Depends: $depends
Installed-Size: $installedsize
Description: NVIDIA CUDA SDK example programs, $description
EOF

echo "Creating .deb file: $packagefile"
rm -f ${package}_*.deb
fakeroot dpkg-deb --build $outdir $packagefile

echo "Package info"
dpkg -I $packagefile

echo "Finished"
