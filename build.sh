#!/bin/bash

cat <<EOF | docker run -i --rm -v "$PWD":/out -w /root alpine /bin/sh
apk add gcc make musl-dev openssl-dev
wget "https://curl.haxx.se/download/$(wget https://curl.haxx.se/download/ -q -O- | grep -o 'curl-.*\.tar\.xz"' | sort -r | head -n1 | sed 's/.$//')"
tar xvfJ curl-*.tar.xz 
cd curl-*
./configure --disable-shared --with-ca-fallback
make curl_LDFLAGS=-all-static 
make install
cp /usr/local/bin/curl /out
strip /out/curl
chown $(id -u):$(id -g) /out/curl
EOF
