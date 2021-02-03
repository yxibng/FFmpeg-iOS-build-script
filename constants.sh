#/bin/bash
export FF_VERSION="4.3.1"

SOURCE="ffmpeg-$FF_VERSION"
if [ ! -r $SOURCE ]
then
    echo 'FFmpeg source not found. Trying to download...'
    curl http://www.ffmpeg.org/releases/$SOURCE.tar.bz2 | tar xj \
        || exit 1
fi