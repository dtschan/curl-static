#!/bin/sh
set -e

VERSION=LATEST
#If you prefer a specific version you can set it specifically
#VERSION=7.66.0
GPG_KEY_URL="https://daniel.haxx.se/mykey.asc"
GPG_KEY_PATH="/out/curl-gpg.pub"
#Do not escape the above variables in script below
#change last argument to -xeus for help with debugging
cat <<EOF | docker run -i --rm -v "$PWD":/out --tmpfs /tmp/build:exec -w /tmp/build alpine /bin/sh -eus

#Print failure message we exit unexpectedly
trap 'RC="\$?"; echo "***FAILED! RC=\${RC}"; exit \${RC}' EXIT

#Fetch a url to a location unless it already exists
conditional_fetch () {
  local URL=\$1
  local OUTPUT_PATH=\$2
  if [ -e \${OUTPUT_PATH} ]; then
    echo "Found existing \${OUTPUT_PATH}; reusing..."
  else
    echo "Fetching \${URL} to \${OUTPUT_PATH}..."
    wget "\${URL}" -O "\${OUTPUT_PATH}"
  fi
}

#Determine tarball filename
if [ "$VERSION" = 'LATEST' ]; then
  echo "Determining latest version..."
  TARBALL_FILENAME=\$(wget "https://curl.haxx.se/download/?C=M;O=D" -q -O- | grep -w -m 1 -o 'curl-.*\.tar\.xz"' | sed 's/"$//')
else
  TARBALL_FILENAME=curl-${VERSION}.tar.xz
fi

#Set some variables (depends on tarball filename determined above)
TARBALL_URL=https://curl.haxx.se/download/\${TARBALL_FILENAME}
TARBALL_PATH=/out/\${TARBALL_FILENAME}
FINAL_BIN_PATH=/out/curl

echo "***Fetching \${TARBALL_FILENAME} and files to validate it..."
conditional_fetch "${GPG_KEY_URL}" "${GPG_KEY_PATH}"
conditional_fetch "\${TARBALL_URL}.asc" "\${TARBALL_PATH}.asc"
conditional_fetch "\${TARBALL_URL}" "\${TARBALL_PATH}"

echo "***Validating source..."
apk add gnupg
gpg --import --always-trust ${GPG_KEY_PATH}
gpg --verify \${TARBALL_PATH}.asc \${TARBALL_PATH}

echo "***Unpacking source..."
tar xfJ \${TARBALL_PATH}
cd curl-*

echo "***Installing build dependencies..."
apk add gcc make musl-dev openssl-dev openssl-libs-static file

echo "***configuring..."
./configure --disable-shared --with-ca-fallback
echo "making..."
make curl_LDFLAGS=-all-static

echo "***Finishing up..."
cp src/curl \${FINAL_BIN_PATH}
strip \${FINAL_BIN_PATH}
chown $(id -u):$(id -g) \${FINAL_BIN_PATH}
#Clear the trap so when we exit there is no failure message
trap - EXIT
echo SUCCESS
ls -ld \${FINAL_BIN_PATH}
du -h \${FINAL_BIN_PATH}

EOF
