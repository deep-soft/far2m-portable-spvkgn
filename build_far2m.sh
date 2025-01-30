#!/bin/bash
set -eo pipefail

REPO_DIR=$GITHUB_WORKSPACE
export CCACHE_DIR=$REPO_DIR/.ccache
export DESTDIR=$REPO_DIR/AppDir
BUILD_DIR=build

if [[ "$WXGUI" == "false" ]]; then
  CMAKE_OPTS+=( "-DUSEWX=no" )
fi

[[ -d $REPO_DIR/patches ]] && ( cd $REPO_DIR/far2m && QUILT_PATCHES=$REPO_DIR/patches quilt push -a )

mkdir -p $REPO_DIR/far2m/$BUILD_DIR
cmake -S $REPO_DIR/far2m -B$REPO_DIR/far2m/$BUILD_DIR \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_C_COMPILER_LAUNCHER=/usr/bin/ccache \
  -DCMAKE_CXX_COMPILER_LAUNCHER=/usr/bin/ccache \
  ${CMAKE_OPTS[@]}
  cmake --build $REPO_DIR/far2m/$BUILD_DIR --target install -- -j$(nproc)

# build LuaFar
mkdir -p $REPO_DIR/luafar2m/$BUILD_DIR
cmake -S $REPO_DIR/luafar2m -B$REPO_DIR/luafar2m/$BUILD_DIR \
  -DHIGHLIGHT=yes \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr
cmake --build $REPO_DIR/luafar2m/$BUILD_DIR --target install -- -j$(nproc)

mkdir -p $REPO_DIR/standalone/lib
cp -a $REPO_DIR/far2m/$BUILD_DIR/install/* $REPO_DIR/standalone
install -vm755 $REPO_DIR/AppRun $REPO_DIR/standalone
# copy libs
dpkg-query -L liblua5.1-0-dev libluajit-5.1-dev libonig-dev | grep -e 'liblua5.1.so' -e 'libluajit-5.1.so' -e 'libonig.so' |\
  xargs -I{} cp -vL {} $REPO_DIR/standalone/lib
# Lua Modules
luarocks install moonscript --lua-version=5.1
luarocks install lrexlib-oniguruma --lua-version=5.1
install -vm644 /usr/local/lib/lua/5.1/*.so $REPO_DIR/standalone/lib
cp -a /usr/local/share/lua $REPO_DIR/standalone
# LuaFar
cp -na -t $REPO_DIR/standalone/Plugins/luafar \
  $REPO_DIR/AppDir/usr/lib/far2m/Plugins/luafar/* \
  $REPO_DIR/AppDir/usr/share/far2m/Plugins/luafar/*
cp -a $REPO_DIR/luafar2m/Macros $REPO_DIR/standalone
# standalone
( cd $REPO_DIR/standalone && ./far2m --help >/dev/null && bash -x $REPO_DIR/make_standalone.sh )
# bundle
makeself --keep-umask --nomd5 --nocrc $REPO_DIR/standalone $PKG_NAME.run "FAR2M File Manager" ./AppRun
tar cvf ${PKG_NAME/_${VERSION}}.run.tar $PKG_NAME.run

tar cJvf $REPO_DIR/far2m.tar.xz -C $REPO_DIR/AppDir .

ccache --max-size=50M --show-stats
