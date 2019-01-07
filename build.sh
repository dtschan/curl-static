#!/bin/bash

cat <<EOF | docker run -i --rm -v "$PWD":/out -w /root alpine /bin/sh
apk add gcc make musl-dev openssl-dev
wget https://curl.haxx.se/download/curl-7.63.0.tar.xz
tar xvfJ curl-7.63.0.tar.xz 
cd curl-*
./configure --disable-shared --with-ca-fallback
make curl_LDFLAGS=-all-static 
make install
cp /usr/local/bin/curl /out
strip /out/curl
chown $(id -u):$(id -g) /out/curl
EOF
