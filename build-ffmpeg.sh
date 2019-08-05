#!/bin/sh

# directories
FF_VERSION="4.1.4"
if [[ $FFMPEG_VERSION != "" ]]; then
  FF_VERSION=$FFMPEG_VERSION
fi
SOURCE="ffmpeg-$FF_VERSION"
FAT="FFmpeg-iOS$FF_VERSION"

SCRATCH="scratch$FF_VERSION"
# must be an absolute path
THIN=`pwd`/"thin$FF_VERSION"

# absolute path to x264 library
X264=`pwd`/x264-iOS

#FDK_AAC=`pwd`/../fdk-aac-build-script-for-iOS/fdk-aac-ios

#CONFIGURE_FLAGS="--enable-cross-compile --disable-debug --disable-programs \
#                 --disable-doc --enable-pic"
CONFIGURE_FLAGS="--enable-cross-compile --disable-debug --disable-programs \
--disable-doc --enable-pic --enable-avresample --disable-debug \
--disable-ffprobe \
--disable-ffplay \
--disable-symver \
--disable-muxers \
--disable-demuxers \
--disable-parsers \
--disable-bsfs \
--disable-protocols \
--disable-indevs \
--disable-outdevs \
--disable-filters \
--disable-decoders \
--enable-videotoolbox \
--enable-encoder=h264_videotoolbox \
--enable-avresample \
--enable-swresample \
--enable-swscale \
--enable-decoder=h264_videotoolbox \
--enable-decoder=h264 \
--enable-decoder=aac \
--enable-decoder=flv \
--enable-decoder=rawvideo \
--enable-decoder=pcm_f32le \
--enable-decoder=pcm_f32be \
--enable-decoder=pcm_s16le \
--enable-decoder=pcm_s16be \
--enable-decoder=pcm_u16le \
--enable-decoder=pcm_u16be \
--enable-muxer=flv \
--enable-muxer=rawvideo  \
--enable-muxer=pcm_f32le \
--enable-muxer=pcm_f32be \
--enable-muxer=pcm_s16le \
--enable-muxer=pcm_s16be \
--enable-muxer=pcm_u16le \
--enable-muxer=pcm_u16be \
--enable-demuxer=flv \
--enable-demuxer=h264 \
--enable-demuxer=pcm_s16le \
--enable-encoder=rawvideo \
--enable-encoder=aac \
--enable-encoder=flv \
--enable-encoder=yuv4 \
--enable-encoder=pcm_f32le \
--enable-encoder=pcm_f32be \
--enable-encoder=pcm_s16le \
--enable-encoder=pcm_s16be \
--enable-encoder=pcm_u16le \
--enable-encoder=pcm_u16be \
--enable-protocol=hls \
--enable-protocol=http \
--enable-protocol=https \
--enable-protocol=rtmp \
--enable-indev=avfoundation \
--enable-indev=lavfi \
--enable-filter=format"

if [ "$X264" ]
then
    echo "enable x264"
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264 --enable-encoder=libx264"
fi

if [ "$FDK_AAC" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libfdk-aac --enable-nonfree"
fi

# avresample
#CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-avresample"

ARCHS="arm64 armv7 x86_64 armv7s"

COMPILE="y"
LIPO="y"

DEPLOYMENT_TARGET="8.0"

if [ "$*" ]
then
	if [ "$*" = "lipo" ]
	then
		# skip compile
		COMPILE=
	else
		ARCHS="$*"
		if [ $# -eq 1 ]
		then
			# skip lipo
			LIPO=
		fi
	fi
fi

if [ "$COMPILE" ]
then
	if [ ! `which yasm` ]
	then
		echo 'Yasm not found'
		if [ ! `which brew` ]
		then
			echo 'Homebrew not found. Trying to install...'
                        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
				|| exit 1
		fi
		echo 'Trying to install Yasm...'
		brew install yasm || exit 1
	fi
	if [ ! `which gas-preprocessor.pl` ]
	then
		echo 'gas-preprocessor.pl not found. Trying to install...'
		(curl -L https://github.com/libav/gas-preprocessor/raw/master/gas-preprocessor.pl \
			-o /usr/local/bin/gas-preprocessor.pl \
			&& chmod +x /usr/local/bin/gas-preprocessor.pl) \
			|| exit 1
	fi

	if [ ! -r $SOURCE ]
	then
		echo 'FFmpeg source not found. Trying to download...'
		curl http://www.ffmpeg.org/releases/$SOURCE.tar.bz2 | tar xj \
			|| exit 1
	fi

	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		CFLAGS="-arch $ARCH"
		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
		    PLATFORM="iPhoneSimulator"
		    CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
		else
		    PLATFORM="iPhoneOS"
		    CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
		    if [ "$ARCH" = "arm64" ]
		    then
		        EXPORT="GASPP_FIX_XCODE5=1"
		    fi
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang"

		# force "configure" to use "gas-preprocessor.pl" (FFmpeg 3.3)
		if [ "$ARCH" = "arm64" ]
		then
		    AS="gas-preprocessor.pl -arch aarch64 -- $CC"
		else
		    AS="gas-preprocessor.pl -- $CC"
		fi

		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"
		if [ "$X264" ]
		then
			CFLAGS="$CFLAGS -I$X264/include"
			LDFLAGS="$LDFLAGS -L$X264/lib"
		fi
		if [ "$FDK_AAC" ]
		then
			CFLAGS="$CFLAGS -I$FDK_AAC/include"
			LDFLAGS="$LDFLAGS -L$FDK_AAC/lib"
		fi

		TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
		    --target-os=darwin \
		    --arch=$ARCH \
		    --cc="$CC" \
		    --as="$AS" \
		    $CONFIGURE_FLAGS \
		    --extra-cflags="$CFLAGS" \
		    --extra-ldflags="$LDFLAGS" \
		    --prefix="$THIN/$ARCH" \
		|| exit 1

		make -j$(nproc) install $EXPORT || exit 1
		cd $CWD
	done
fi

if [ "$LIPO" ]
then
	echo "building fat binaries..."
	mkdir -p $FAT/lib
	set - $ARCHS
	CWD=`pwd`
	cd $THIN/$1/lib
	for LIB in *.a
	do
		cd $CWD
		echo lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB 1>&2
		lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB || exit 1
	done

	cd $CWD
	cp -rf $THIN/$1/include $FAT
fi

echo Done
