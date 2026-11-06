# tls.mk --
#
#	Cross-builds OpenSSL and tcltls for Android as static libraries, which
#	are linked into libmain.so of the APK, and tlsinit.o, which registers
#	tcltls as a static package. Run by build.sh in the tk-android-build
#	image (the NDK clang wrappers are on its PATH), after Tcl is built in
#	BUILD.
#
#	make -f tls.mk BUILD=dir SRC=dir [ANDROID_ABI=arm64-v8a]
#
#	SRC holds the unpacked sources: openssl-3.6.5 and tcltls2.0.1.

BUILD		?= $(error BUILD is not set)
SRC		?= $(error SRC is not set)
HERE		:= $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ANDROID_API	?= 30
ANDROID_ABI	?= arm64-v8a

ifeq ($(ANDROID_ABI),x86_64)
  TRIPLE	:= x86_64-linux-android
  SSL_TARGET	:= android-x86_64
else ifeq ($(ANDROID_ABI),arm64-v8a)
  TRIPLE	:= aarch64-linux-android
  SSL_TARGET	:= android-arm64
else
  $(error ANDROID_ABI must be x86_64 or arm64-v8a)
endif

CC		:= $(TRIPLE)$(ANDROID_API)-clang
TOOLCHAIN	:= CC=$(CC) AR=llvm-ar RANLIB=llvm-ranlib
CFLAGS		:= -O2 -g -fPIC -ffunction-sections -fdata-sections
NDK		?= /opt/android-ndk-r29
NPROC		:= $(shell nproc)

PREFIX		:= $(BUILD)/prefix
SSL_PREFIX	:= $(BUILD)/ssl
HOST_TCLSH	:= $(abspath $(BUILD)/../android-host)/bin/tclsh9.1

all: openssl tcltls tlsinit

# ==== OpenSSL ====

openssl: $(SSL_PREFIX)/lib/libssl.a

$(SSL_PREFIX)/lib/libssl.a:
	mkdir -p $(BUILD)/openssl
	cd $(BUILD)/openssl && \
	    ANDROID_NDK_ROOT=$(NDK) $(SRC)/openssl-3.6.5/Configure \
		$(SSL_TARGET) -D__ANDROID_API__=$(ANDROID_API) \
		no-shared no-tests no-docs no-apps no-module \
		--prefix=$(SSL_PREFIX) --libdir=lib \
		--openssldir=/system/etc/security && \
	    ANDROID_NDK_ROOT=$(NDK) $(MAKE) -j$(NPROC) build_libs && \
	    $(MAKE) install_dev

# ==== tcltls ====

tcltls: $(BUILD)/tcltls/.built

$(BUILD)/tcltls/.built: $(SSL_PREFIX)/lib/libssl.a
	mkdir -p $(BUILD)/tcltls
	cd $(BUILD)/tcltls && \
	    $(TOOLCHAIN) CFLAGS="$(CFLAGS)" \
	    $(SRC)/tcltls2.0.1/configure --host=$(TRIPLE) \
		--with-tcl=$(PREFIX)/lib --with-tclinclude=$(PREFIX)/include \
		--with-openssl-dir=$(SSL_PREFIX) --enable-static-ssl \
		--disable-shared && \
	    $(MAKE) -j$(NPROC) binaries TCLSH_PROG=$(HOST_TCLSH)
	touch $@

# ==== Registration of the static package ====

tlsinit: $(BUILD)/tlsinit.o

$(BUILD)/tlsinit.o: $(HERE)/tlsinit.c
	$(CC) $(CFLAGS) -I$(PREFIX)/include -c $< -o $@

.PHONY: all openssl tcltls tlsinit
