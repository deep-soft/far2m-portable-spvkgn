#!/bin/bash

REPO_DIR=$GITHUB_WORKSPACE
export CCACHE_DIR=$REPO_DIR/.ccache
export DESTDIR=$REPO_DIR/AppDir
BUILD_DIR=build

if [[ "$STANDALONE" == "true" ]]; then
  CMAKE_OPTS+=( "-DUSEWX=no" )
fi

QUILT_PATCHES=$REPO_DIR/patches quilt push -a

mkdir -p $BUILD_DIR && \
( cd $BUILD_DIR && \
  cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_C_COMPILER_LAUNCHER=/usr/bin/ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=/usr/bin/ccache \
    ${CMAKE_OPTS[@]} .. && \
    ninja && ninja install/strip ) && \

tar cJvf $REPO_DIR/far2m.tar.xz -C $REPO_DIR/AppDir .

if [[ "$STANDALONE" == "true" ]]; then
  ( cd $BUILD_DIR/install && ./far2m --help >/dev/null && bash -x $REPO_DIR/make_standalone.sh ) && \
  ( cd $REPO_DIR && makeself --keep-umask far2m/$BUILD_DIR/install $PKG_NAME.run "FAR2M File Manager" ./far2m && \
    tar cvf ${PKG_NAME/_${VERSION}}.run.tar $PKG_NAME.run )
fi

ccache --max-size=50M --show-stats
