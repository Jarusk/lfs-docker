FROM alpine:3.6

#USER lfs
ARG jobs=4

RUN apk add --no-cache bash binutils bison bzip2 coreutils diffutils
RUN apk add --no-cache findutils gawk grep gzip m4 make openssl
RUN apk add --no-cache libc-dev python-dev gcc g++ ca-certificates
RUN apk add --no-cache openssl-dev patch perl sed tar texinfo wget xz

ENV LFS_TGT=x86_64-lfs-linux-gnu
ENV LFS=/lfs
ENV PATH=/tools/bin:/bin:/usr/bin

WORKDIR /lfs/sources

RUN mkdir /lfs/tools
RUN ln -s /lfs/tools /

RUN wget -O wget-list http://www.linuxfromscratch.org/lfs/downloads/8.1-systemd/wget-list
RUN wget --input-file=wget-list

#################################################################
# Binutils
#################################################################
WORKDIR /lfs/sources
RUN tar xvf binutils-2.29.tar.bz2
WORKDIR /lfs/sources/binutils-2.29/build

RUN ../configure --prefix=/tools            \
             --with-sysroot=$LFS        \
             --with-lib-path=/tools/lib \
             --target=$LFS_TGT          \
             --disable-nls              \
             --disable-werror

RUN make -j$jobs

RUN case $(uname -m) in \
  x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;\
esac

RUN make install
WORKDIR /lfs/sources
RUN rm -rf binutils-2.29/


#################################################################
# GCC
#################################################################
WORKDIR /lfs/sources
RUN tar xvf gcc-7.2.0.tar.xz
WORKDIR /lfs/sources/gcc-7.2.0/

RUN tar -xf ../mpfr-3.1.5.tar.xz
RUN mv -v mpfr-3.1.5 mpfr
RUN tar -xf ../gmp-6.1.2.tar.xz
RUN mv -v gmp-6.1.2 gmp
RUN tar -xf ../mpc-1.0.3.tar.gz
RUN mv -v mpc-1.0.3 mpc

COPY gcc-patch-script.sh .
RUN chmod +x gcc-patch-script.sh
RUN ./gcc-patch-script.sh

WORKDIR /lfs/sources/gcc-7.2.0/build/

RUN ../configure                                   \
    --target=$LFS_TGT                              \
    --prefix=/tools                                \
    --with-glibc-version=2.11                      \
    --with-sysroot=$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libmpx                               \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++

RUN make -j$jobs
RUN make install
WORKDIR /lfs/sources
RUN rm -rf gcc-7.2.0/


#################################################################
# Linux Headers
#################################################################
WORKDIR /lfs/sources
RUN tar xvf linux-4.12.7.tar.xz
WORKDIR /lfs/sources/linux-4.12.7/

RUN make mrproper
RUN make INSTALL_HDR_PATH=dest headers_install
RUN cp -rv dest/include/* /tools/include

WORKDIR /lfs/sources
RUN rm -rf linux-4.12.7


#################################################################
# glibc
#################################################################
WORKDIR /lfs/sources
RUN tar xvf glibc-2.26.tar.xz
WORKDIR /lfs/sources/glibc-2.26/build/

RUN ../configure                         \
      --prefix=/tools                    \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=3.2                \
      --with-headers=/tools/include      \
      libc_cv_forced_unwind=yes          \
      libc_cv_c_cleanup=yes

RUN make -j$jobs
RUN make install

WORKDIR /lfs/sources
RUN rm -rf glibc-2.26


#################################################################
# libstdc++
#################################################################
WORKDIR /lfs/sources
RUN tar xvf gcc-7.2.0.tar.xz
WORKDIR /lfs/sources/gcc-7.2.0/build/

RUN ../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/7.2.0

RUN make -j$jobs
RUN make install
WORKDIR /lfs/sources
RUN rm -rf gcc-7.2.0/


#################################################################
# Binutils Pass 2
#################################################################
WORKDIR /lfs/sources
RUN tar xvf binutils-2.29.tar.bz2
WORKDIR /lfs/sources/binutils-2.29/build

RUN CC=$LFS_TGT-gcc                \
    AR=$LFS_TGT-ar                 \
    RANLIB=$LFS_TGT-ranlib         \
    ../configure                   \
        --prefix=/tools            \
        --disable-nls              \
        --disable-werror           \
        --with-lib-path=/tools/lib \
        --with-sysroot

RUN make -j$jobs
RUN make install

RUN make -C ld clean
RUN make -C ld LIB_PATH=/usr/lib:/lib
RUN cp -v ld/ld-new /tools/bin

WORKDIR /lfs/sources
RUN rm -rf binutils-2.29/


#################################################################
# GCC Pass 2
#################################################################
WORKDIR /lfs/sources
RUN tar xvf gcc-7.2.0.tar.xz
WORKDIR /lfs/sources/gcc-7.2.0/

RUN cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h

RUN tar -xf ../mpfr-3.1.5.tar.xz
RUN mv -v mpfr-3.1.5 mpfr
RUN tar -xf ../gmp-6.1.2.tar.xz
RUN mv -v gmp-6.1.2 gmp
RUN tar -xf ../mpc-1.0.3.tar.gz
RUN mv -v mpc-1.0.3 mpc

COPY gcc-patch-script.sh .
RUN chmod +x gcc-patch-script.sh
RUN ./gcc-patch-script.sh

WORKDIR /lfs/sources/gcc-7.2.0/build/

RUN CC=$LFS_TGT-gcc                                    \
    CXX=$LFS_TGT-g++                                   \
    AR=$LFS_TGT-ar                                     \
    RANLIB=$LFS_TGT-ranlib                             \
    ../configure                                       \
        --prefix=/tools                                \
        --with-local-prefix=/tools                     \
        --with-native-system-header-dir=/tools/include \
        --enable-languages=c,c++                       \
        --disable-libstdcxx-pch                        \
        --disable-multilib                             \
        --disable-bootstrap                            \
        --disable-libgomp

RUN make -j$jobs
RUN make install
RUN ln -sv gcc /tools/bin/cc
WORKDIR /lfs/sources
RUN rm -rf gcc-7.2.0/

# All done
#CMD ["/bin/bash"]
