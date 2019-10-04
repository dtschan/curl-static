#!/bin/sh

VERSION=7.66.0
TARBALL_FILENAME=curl-${VERSION}.tar.xz
TARBALL_PATH=/out/${TARBALL_FILENAME}
FINAL_BIN_PATH=/out/curl
URL=https://curl.haxx.se/download/${TARBALL_FILENAME}
cat <<EOF | docker run -i --rm -v "$PWD":/out -w /root alpine /bin/sh -eus
trap 'RC="\$?"; echo "***FAILED! RC=\${RC}"; exit \${RC}' EXIT
apk add gcc make musl-dev openssl-dev
if [ -e ${TARBALL_PATH} ]; then 
  echo "Found existing ${TARBALL_FILENAME}; reusing..."
else 
  echo "Fetching ${URL}..."
  wget ${URL} -O ${TARBALL_PATH}
fi
tar xfJ ${TARBALL_PATH}
cd curl-*
./configure --disable-shared --with-ca-fallback
make curl_LDFLAGS=-all-static 
make install
cp /usr/local/bin/curl ${FINAL_BIN_PATH}
strip ${FINAL_BIN_PATH}
chown $(id -u):$(id -g) ${FINAL_BIN_PATH}
trap - EXIT
echo SUCCESS
ls -l ${FINAL_BIN_PATH}
EOF
