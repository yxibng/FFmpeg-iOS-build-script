SCRIPT_DIR="$(
    cd "$(dirname "$0")"
    pwd
)"

source $SCRIPT_DIR/constants.sh

SOURCE="ffmpeg-$FF_VERSION"
OUTPUT=$SCRIPT_DIR/ffmpeg-macos

#clean last build
if [ -f $OUTPUT ]; then 
	rm -rf $OUTPUT
fi

#make output dir
mkdir -p $OUTPUT



# absolute path to x264 library
X264=`pwd`/../x264-ios/x264-macos


CONFIGURE_FLAGS="--disable-debug \
				--enable-static \
				--disable-programs \
				--disable-symver \
				--disable-htmlpages \
				--disable-manpages \
				--disable-podpages \
				--disable-avdevice \
				--disable-cuda \
				--disable-cuvid \
				--disable-nvenc \
				--disable-lzma \
                --disable-doc --enable-pic --disable-asm --disable-inline-asm"

#test if link to x264
if [ -f $X264 ]
then
	echo "x264 exist, set link config, path = $X264"
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264"
fi


CFLAGS="-arch x86_64 -fvisibility=hidden -fembed-bitcode -mmacosx-version-min=10.12"

LDFLAGS=""

if [ -f $X264 ]
then
	CFLAGS="$CFLAGS -I$X264/include"
	LDFLAGS="$LDFLAGS -L$X264/lib"
fi

SDKPATH=`xcrun --show-sdk-path`
SYSROOT="--sysroot=$SDKPATH"

cd $SOURCE
./configure $CONFIGURE_FLAGS $SYSROOT --extra-cflags="$CFLAGS" --extra-ldflags="$LDFLAGS"  --prefix=$OUTPUT

make -j`nproc`

make install || exit 1

