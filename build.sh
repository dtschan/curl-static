#!/bin/sh


VERSION=LATEST
#If you prefer a specific version you can set it specifically
#VERSION=7.66.0
cat <<EOF | docker run -i --rm -v "$PWD":/out -w /root alpine /bin/sh -eus
trap 'RC="\$?"; echo "***FAILED! RC=\${RC}"; exit \${RC}' EXIT
if [ "$VERSION" = 'LATEST' ]; then
  TARBALL_FILENAME=\$(wget https://curl.haxx.se/download/ -q -O- | grep -o 'curl-.*\.tar\.xz"' | sort -rn | head -n1 | sed 's/"$//')
else
  TARBALL_FILENAME=curl-${VERSION}.tar.xz
fi
URL=https://curl.haxx.se/download/\${TARBALL_FILENAME}
TARBALL_PATH=/out/\${TARBALL_FILENAME}
FINAL_BIN_PATH=/out/curl
echo "Building \${TARBALL_FILENAME}..."
apk add gcc make musl-dev openssl-dev
if [ -e \${TARBALL_PATH} ]; then 
  echo "Found existing \${TARBALL_FILENAME}; reusing..."
else 
  echo "Fetching \${URL}..."
  wget \${URL} -O \${TARBALL_PATH}
fi
tar xfJ \${TARBALL_PATH}
cd curl-*
./configure --disable-shared --with-ca-fallback
make curl_LDFLAGS=-all-static 
make install
cp /usr/local/bin/curl \${FINAL_BIN_PATH}
strip \${FINAL_BIN_PATH}
chown $(id -u):$(id -g) \${FINAL_BIN_PATH}
trap - EXIT
echo SUCCESS
ls -l \${FINAL_BIN_PATH}
EOF
