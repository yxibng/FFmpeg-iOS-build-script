SCRIPT_DIR="$(
    cd "$(dirname "$0")"
    pwd
)"

source $SCRIPT_DIR/constants.sh

SOURCE="ffmpeg-$FF_VERSION"
OUTPUT=$SCRIPT_DIR/ffmpeg-macos

mkdir $OUTPUT



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

if [ "$X264" ]
then
	echo "================"
	echo $X264
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264"
fi


CFLAGS="-arch x86_64 -fvisibility=hidden -fembed-bitcode --mmacosx-version-min=10.10"

LDFLAGS=""

if [ "$X264" ]
then
	CFLAGS="$CFLAGS -I$X264/include"
	LDFLAGS="$LDFLAGS -L$X264/lib"
fi

HOST="--host=x86_64-apple-darwin"

cd $SOURCE
./configure $CONFIGURE_FLAGS $HOST --extra-cflags="$CFLAGS" --extra-ldflags="$LDFLAGS"  --prefix=$OUTPUT

make -j`nproc`

make install || exit 1

