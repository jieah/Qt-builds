#!/bin/bash

#
# The BSD 3-Clause License. http://www.opensource.org/licenses/BSD-3-Clause
#
# This file is part of 'Qt-builds' project.
# Copyright (c) 2013 by Alexpux (alexpux@gmail.com)
# All rights reserved.
#
# Project: Qt-builds ( https://github.com/Alexpux/Qt-builds )
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# - Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the distribution.
# - Neither the name of the 'Qt-builds' nor the names of its contributors may
#     be used to endorse or promote products derived from this software
#     without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# **************************************************************************

P=zlib
P_V=${P}-${ZLIB_VERSION}
SRC_FILE="${P_V}.tar.bz2"
URL=http://zlib.net/${SRC_FILE}
DEPENDS=()

src_download() {
	func_download $P_V ".tar.bz2" $URL
}

src_unpack() {
	func_uncompress $P_V ".tar.bz2" $BUILD_DIR
}

src_patch() {
	local _patches=(
		$P/zlib-1.2.5-nostrip.patch
		$P/zlib-1.2.5-tml.patch
	)
	
	func_apply_patches \
		$P_V \
		_patches[@] \
		$BUILD_DIR
}

src_configure() {
	# local _conf_flags=(
		# --prefix=${PREFIX}
		# --host=${HOST}
		# ${SHARED_LINK_FLAGS}
		# --disable-rpath
		# CFLAGS="\"${HOST_CFLAGS}\""
		# LDFLAGS="\"${HOST_LDFLAGS}\""
		# CPPFLAGS="\"${HOST_CPPFLAGS}\""
	# )
	# local _allconf="${_conf_flags[@]}"
	# func_configure $P_V $P_V "$_allconf"
	echo "--> Configure empty"
}

pkg_build() {
	local _make_flags=(
		${MAKE_OPTS}
		-f win32/Makefile.gcc
		CC=${HOST}-gcc
		AR=ar
		RC=windres
		DLLWRAP=dllwrap
		STRIP=strip
		$( [[ $STATIC_DEPS == yes ]] \
			&& echo "LOC=\"${HOST_LDFLAGS}\"" \
		)
		all
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		${P_V} \
		"/bin/make" \
		"$_allmake" \
		"building..." \
		"built"

	if ! [ -f $BUILD_DIR/$P_V/pkgconfig.marker ]
	then
		pushd $BUILD_DIR/$P_V > /dev/null
		sed \
			-e 's|@prefix@|'${PREFIX}'|g' \
			-e 's|@exec_prefix@|${prefix}|g' \
			-e 's|@libdir@|${prefix}/lib|g' \
			-e 's|@sharedlibdir@|${prefix}/bin|g' \
			-e 's|@includedir@|${prefix}/include|g' \
			-e 's|@VERSION@|'${ZLIB_VERSION}'|g' \
			zlib.pc.in > zlib.pc || die "SED error"
		touch pkgconfig.marker
		popd > /dev/null
	fi
}

pkg_install() {

	local _install_flags=(
		-f win32/Makefile.gcc
		INCLUDE_PATH=${PREFIX}/include
		LIBRARY_PATH=${PREFIX}/lib
		BINARY_PATH=${PREFIX}/bin
		$( [[ $STATIC_DEPS == no ]] \
			&& echo "SHARED_MODE=1" \
		)
		install
	)

	local _allinstall="${_install_flags[@]}"
	func_make \
		${P_V} \
		"/bin/make" \
		"$_allinstall" \
		"installing..." \
		"installed"

	if ! [ -f $BUILD_DIR/$P_V/pkg_install.marker ]
	then
		cp -f $BUILD_DIR/$P_V/zlib.pc ${PREFIX}/lib/pkgconfig/
		[[ $STATIC_DEPS == no ]] && {
			rm -f ${PREFIX}/lib/libz.a
		}
		touch $BUILD_DIR/$P_V/pkg_install.marker
	fi
}
