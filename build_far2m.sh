#!/bin/bash

REPO_DIR=$GITHUB_WORKSPACE
export CCACHE_DIR=$REPO_DIR/.ccache
export DESTDIR=$REPO_DIR/AppDir
BUILD_DIR=build

if [[ "$STANDALONE" == "true" ]]; then
  CMAKE_OPTS+=( "-DUSEWX=no" )
fi

( cd $REPO_DIR/far2m && QUILT_PATCHES=$REPO_DIR/patches quilt push -a )

mkdir -p $REPO_DIR/far2m/$BUILD_DIR && \
cmake -G Ninja -H$REPO_DIR/far2m -B$REPO_DIR/far2m/$BUILD_DIR \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_VERBOSE_MAKEFILE=ON \
  -DCMAKE_C_COMPILER_LAUNCHER=/usr/bin/ccache \
  -DCMAKE_CXX_COMPILER_LAUNCHER=/usr/bin/ccache \
  ${CMAKE_OPTS[@]} && \
  ninja -C $REPO_DIR/far2m/$BUILD_DIR install/strip && \

# build LuaFar
mkdir -p $REPO_DIR/luafar2m/$BUILD_DIR && \
cmake -H$REPO_DIR/luafar2m -B$REPO_DIR/luafar2m/$BUILD_DIR \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_VERBOSE_MAKEFILE=ON && \
cmake --build $REPO_DIR/luafar2m/$BUILD_DIR --target install -- -j$(nproc) && \

if [[ "$STANDALONE" == "true" ]]; then
  mkdir -p $REPO_DIR/standalone && cp -a $REPO_DIR/far2m/$BUILD_DIR/install/* $REPO_DIR/standalone && \
  install -vm755 $REPO_DIR/AppRun $REPO_DIR/standalone && \
  cp -na -t $REPO_DIR/standalone/Plugins/luafar \
    $REPO_DIR/AppDir/usr/lib/far2m/Plugins/luafar/* \
    $REPO_DIR/AppDir/usr/share/far2m/Plugins/luafar/* && \
  cp -a $REPO_DIR/luafar2m/Macros $REPO_DIR/standalone && \
  ( cd $REPO_DIR/standalone && ./far2m --help >/dev/null && bash -x $REPO_DIR/make_standalone.sh ) && \
  makeself --keep-umask --nomd5 --nocrc $REPO_DIR/standalone $PKG_NAME.run "FAR2M File Manager" ./AppRun && \
  tar cvf ${PKG_NAME/_${VERSION}}.run.tar $PKG_NAME.run
fi && \

tar cJvf $REPO_DIR/far2m.tar.xz -C $REPO_DIR/AppDir .

ccache --max-size=50M --show-stats
