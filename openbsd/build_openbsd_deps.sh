#!/bin/sh

#
# Don't forget to fix /usr/include/netdb.h
# comment out getnameinfo() stuff
#

ldconfig -m /usr/local/lib
grep -q ldconfig /root/.profile
if [ "$?" = 1 ]; then
 echo "ldconfig -m /usr/local/lib" > /root/.profile
fi

VERSION=`uname -r`
UPDATE=no

export PKG_PATH=http://ftp.eu.openbsd.org/pub/OpenBSD/${VERSION}/packages/`machine -a`/
echo $PKG_PATH

if [ $UPDATE = "yes" ] && [ $VERSION = "5.0" ]; then
 echo "/usr/sbin/pkg_add -v flex bison gmake bash automake-1.11.1p2 autoconf-2.68 libtool"
 /usr/sbin/pkg_add -v flex bison gmake bash automake-1.11.1p2 autoconf-2.68 libtool
fi

if [ $UPDATE = "yes" ] && [ $VERSION = "5.3" ]; then
 echo "/usr/sbin/pkg_add -v flex bison gmake bash automake-1.11.1p2 autoconf-2.68 libtool"
 /usr/sbin/pkg_add -v flex bison gmake bash automake-1.11.1p2 autoconf-2.68 libtool
fi

if [ $UPDATE = "yes" ] && [ $VERSION = "5.4" ]; then
 echo "/usr/sbin/pkg_add -v flex bison gmake bash automake-1.11.1p2 autoconf-2.68 libtool"
 /usr/sbin/pkg_add -v flex bison gmake bash automake-1.11.1p2 autoconf-2.68 libtool
fi

if [ $UPDATE = "yes" ] && [ $VERSION = "5.5" ]; then
 echo "/usr/sbin/pkg_add -v flex bison gmake bash automake-1.14.1 autoconf-2.69p1 libtool"
 /usr/sbin/pkg_add -v flex bison gmake bash automake-1.14.1 autoconf-2.69p1 libtool
fi

# prepare shell environments
export LDFLAGS="-L/var/cfengine/lib -R/var/cfengine/lib" 
export CFLAGS="-I/var/cfengine/include"
export LD_LIBRARY_PATH=/var/cfengine/lib
export LD_RUN_PATH=/var/cfengine/lib

# where tarballs located
SOURCE_DIR=/usr/local/src/deps-to-build

# Cfengine libary directory
CFENGINE_LIB=/var/cfengine/lib
mkdir -p $CFENGINE_LIB /var/cfengine/include || true

# Enable/Disable dep flags
# Normal build
ENABLE_BZIP2=0
ENABLE_ZLIB=0
ENABLE_DB=0
ENABLE_OPENSSL=1
ENABLE_FIPS=0
ENABLE_PCRE=0
ENABLE_LMDB=0
ENABLE_TOKYOCABINET=0
ENABLE_POSTGRESQL=0
ENABLE_OPENLDAP=0
ENABLE_MYSQL=0
ENABLE_LIBXML2=0
ENABLE_YAML=0

# tarball variables
BZIP2=bzip2-1.0.6                  # need to go down and recheck
ZLIB=zlib-1.2.5
DB=db-5.1.19.NC
OPENSSL_FIPS=openssl-fips-1.2      # OPENSSL FIPS-140-2 go down and recheck ./configure line
OPENSSL=openssl-0.9.8zg            # normal OPENSSL
PCRE=pcre-8.36
TOKYOCABINET=tokyocabinet-1.4.48
POSTGRESQL=postgresql-8.4.4
OPENLDAP=openldap-2.4.16           # need to go down and recheck
MYSQL=mysql-5.1.53
LMDB=mdb-mdb-7cab7b95e240446dd11c7e0951af8b2c3409765b
LIBXML2=libxml2-2.9.2
YAML=yaml-0.1.5

# remove old directories
rm -rf $SOURCE_DIR/$BZIP2
rm -rf $SOURCE_DIR/$ZLIB
rm -rf $SOURCE_DIR/$DB
rm -rf $SOURCE_DIR/$OPENSSL_FIPS
rm -rf $SOURCE_DIR/$OPENSSL
rm -rf $SOURCE_DIR/$PCRE
rm -rf $SOURCE_DIR/$TOKYOCABINET
rm -rf $SOURCE_DIR/$POSTGRESQL
rm -rf $SOURCE_DIR/$OPENLDAP
rm -rf $SOURCE_DIR/$MYSQL
rm -rf $SOURCE_DIR/$LIBXML2
rm -rf $SOURCE_DIR/mdb-mdb
rm -rf $SOURCE_DIR/$YAML

# start compiling zlib
if [ $ENABLE_ZLIB = 1 ]; then
 cd $SOURCE_DIR
 tar xvfz $ZLIB.tar.gz
 cd $SOURCE_DIR/$ZLIB
 ./configure --prefix=/var/cfengine && make && make install
 cd /var/cfengine/lib
 rm libz.so
 rm libz.so.1
 cp libz.so.1.2.5 libz.so
 cp libz.so.1.2.5 libz.so.1
fi

# start compiling bzip2
if [ $ENABLE_BZIP2 = 1 ]; then
 cd $SOURCE_DIR
 tar xvfz $BZIP2.tar.gz
 cd $SOURCE_DIR/$BZIP2
 make -f Makefile-libbz2_so
 rm -f $CFENGINE_LIB/libbz2.so*
 cp $SOURCE_DIR/$BZIP2/libbz2.so.1.0.6 $CFENGINE_LIB
 cp $SOURCE_DIR/$BZIP2/bzlib.h /var/cfengine/include
 cd $CFENGINE_LIB
 cp libbz2.so.1.0.6 libbz2.so.1.0
 cp libbz2.so.1.0.6 libbz2.so.1
 cp libbz2.so.1.0.6 libbz2.so
fi

# start compiling db
if [ $ENABLE_DB = 1 ]; then
 cd $SOURCE_DIR
 tar xvfz $DB.tar.gz
 cd $SOURCE_DIR/$DB/build_unix/
 ../dist/configure --prefix=/var/cfengine && make && make install
fi

# start compiling openssl
# For OPENSSL FIPS-140-2 canister
if [ $ENABLE_FIPS = 1 ] && [ $ENABLE_OPENSSL = 1 ]; then
 cd $SOURCE_DIR
 tar xvfz $OPENSSL_FIPS.tar.gz
 cd $SOURCE_DIR/$OPENSSL_FIPS
 ./config fipscanisterbuild shared --prefix=/var/cfengine/tmpfips && make && make install
 # Then normal OPENSSL
 cd $SOURCE_DIR
 tar xvfz $OPENSSL.tar.gz
 cd $SOURCE_DIR/$OPENSSL
 ./config fips no-ec shared no-dtls no-psk no-srp --prefix=/var/cfengine --with-fipslibdir=/var/cfengine/tmpfips/lib && make && make install
elif [ $ENABLE_FIPS = 0 ] && [ $ENABLE_OPENSSL = 1 ]; then
 # Compile OPENSSL without FIPS module
 cd $SOURCE_DIR
 tar xvfz $OPENSSL.tar.gz
 cd $SOURCE_DIR/$OPENSSL
 ./config no-ec shared no-dtls no-psk no-srp --prefix=/var/cfengine && make depend && make && make install
fi

# start compiling lmdb
if [ $ENABLE_LMDB = 1 ]; then
 cd $SOURCE_DIR
 tar xvfz $LMDB.tar.gz
 cd $SOURCE_DIR/mdb-mdb/libraries/liblmdb
 make
 cp liblmdb.a /var/cfengine/lib/
 cp liblmdb.so /var/cfengine/lib/liblmdb.so.0
 cp liblmdb.so /var/cfengine/lib/liblmdb.so
 cp lmdb.h /var/cfengine/include/
 # cp mdb_stat mdb_copy /var/cfengine/bin/
 # cp mdb_stat.a mdb_copy.1 /usr/local/man/man1/
 # cp mdb_stat.1 mdb_copy.1 /usr/local/man/man1/
fi

# start compiling pcre
if [ $ENABLE_PCRE = 1 ]; then
 cd $SOURCE_DIR
 tar xvfz $PCRE.tar.gz
 cd $SOURCE_DIR/$PCRE
 ./configure --prefix=/var/cfengine --enable-unicode-properties && make && make install
fi

# start compiling tokyocabinet
if [ $ENABLE_TOKYOCABINET = 1 ]; then
 cd $SOURCE_DIR
 tar xvfz $TOKYOCABINET.tar.gz
 cd $SOURCE_DIR/$TOKYOCABINET
 ./configure --enable-off64 --prefix=/var/cfengine --disable-zlib --disable-bzip && LD_LIBRARY_PATH=/usr/local/lib gmake && LD_LIBRARY_PATH=/usr/local/lib gmake install
 cd $CFENGINE_LIB
 rm libtokyocabinet.so
 rm libtokyocabinet.so.9
 cp libtokyocabinet.so.9.11.0 libtokyocabinet.so
 cp libtokyocabinet.so.9.11.0 libtokyocabinet.so.9
fi

# start compiling postgresql
if [ $ENABLE_POSTGRESQL = 1 ]; then
 cd $SOURCE_DIR
 tar xvfz $POSTGRESQL.tar.gz
 cd $SOURCE_DIR/$POSTGRESQL
 ./configure --prefix=/var/cfengine --without-readline && LD_LIBRARY_PATH=/usr/local/lib gmake && LD_LIBRARY_PATH=/usr/local/lib gmake install
fi

# start compiling openldap
if [ $ENABLE_OPENLDAP = 1 ]; then
 cd $SOURCE_DIR
 tar xvfz openldap-stable-20090411.tgz
 cd $SOURCE_DIR/$OPENLDAP
 ./configure --prefix=/var/cfengine --enable-shared --disable-static --disable-slapd --disable-backends --with-tls=openssl LDFLAGS="-L/var/cfengine/lib" CPPFLAGS="-I/var/cfengine/include -D_GNU_SOURCE" && make && make install
fi

# start compiling mysql
if [ $ENABLE_MYSQL = 1 ]; then
 cd $SOURCE_DIR
 tar xvfz $MYSQL.tar.gz
 cd $MYSQL
 if [ "`machine -a`" = "i386" ]; then
  CXX=gcc CXXFLAGS="-felide-constructors -fno-exceptions -fno-rtti" ./configure --prefix=/var/cfengine --without-server --with-low-memory --without-docs --without-readline --enable-shared --enable-thread-safe-client --enable-assembler && make && make install
 else 
  if [ "`machine -a`" = "amd64" ]; then
   CXX=gcc CXXFLAGS="-felide-constructors -fno-exceptions -fno-rtti" ./configure --prefix=/var/cfengine --without-server --with-low-memory --without-doc --without-readline --enable-shared --enable-thread-safe-client && make && make install
  fi
 fi
 cd /var/cfengine/lib
 cp -pr mysql/* .
 rm -rf mysql
 echo "`/usr/bin/sed -e '/libdir/d' < /var/cfengine/lib/libmysqlclient.la`" > /var/cfengine/lib/libmysqlclient.la && echo "libdir='/var/cfengine/lib'" >> /var/cfengine/lib/libmysqlclient.la
 echo "`/usr/bin/sed -e '/libdir/d' < /var/cfengine/lib/libmysqlclient_r.la`" > /var/cfengine/lib/libmysqlclient_r.la && echo "libdir='/var/cfengine/lib'" >> /var/cfengine/lib/libmysqlclient_r.la
fi

# start compiling libxml2
if [ $ENABLE_LIBXML2 = 1 ]; then
 cd $SOURCE_DIR
 tar xvfz $LIBXML2.tar.gz
 cd $LIBXML2
 ./configure --prefix=/var/cfengine --without-zlib --without-iconv && make && make install
 ln -s libxml2/libxml libxml
fi

# start compiling yaml
if [ $ENABLE_YAML = 1 ]; then
 cd $SOURCE_DIR
 tar xvfz $YAML.tar.gz
 cd $SOURCE_DIR/$YAML
 ./configure --prefix=/var/cfengine && make && make install
fi

# tidy up for a tiny HDD system
rm -rf $SOURCE_DIR/$BZIP2
rm -rf $SOURCE_DIR/$ZLIB
rm -rf $SOURCE_DIR/$DB
rm -rf $SOURCE_DIR/$OPENSSL_FIPS
rm -rf $SOURCE_DIR/$OPENSSL
rm -rf $SOURCE_DIR/$PCRE
rm -rf $SOURCE_DIR/$TOKYOCABINET
rm -rf $SOURCE_DIR/$POSTGRESQL
rm -rf $SOURCE_DIR/$OPENLDAP
rm -rf $SOURCE_DIR/$MYSQL
rm -rf $SOURCE_DIR/$LIBXML2
rm -rf $SOURCE_DIR/mdb-mdb
rm -rf $SOURCE_DIR/$YAML

echo ""
echo "  ***** SUMMARY *****"
echo ""

# verification
if [ -f $CFENGINE_LIB/libz.so ]; then
 echo "(1)  ZLIB         ... OK"
else
 echo "(1)  ZLIB         ... FAILED"
fi
if [ -f $CFENGINE_LIB/libbz2.so ]; then
 echo "(2)  LIBBZ2       ... OK"
else
 echo "(2)  LIBBZ2       ... FAILED"
fi
if [ -f $CFENGINE_LIB/libdb.so ]; then
 echo "(3)  BERKELEYDB   ... OK"
else
 echo "(3)  BERKELEYDB   ... FAILED"
fi
if [ -f $CFENGINE_LIB/libssl.so ]; then
 echo "(4)  OPENSSL      ... OK"
else
 echo "(4)  OPENSSL      ... FAILED"
fi
if [ -f $CFENGINE_LIB/libpcre.a ]; then
 echo "(5)  PCRE         ... OK"
else
 echo "(5)  PCRE         ... FAILED"
fi
if [ -f $CFENGINE_LIB/libtokyocabinet.so ]; then
 echo "(6)  TOKYOCABINET ... OK"
else
 echo "(6)  TOKYOCABINET ... FAILED"
fi
if [ -f $CFENGINE_LIB/libpq.so ]; then
 echo "(7)  POSTGRESQL   ... OK"
else
 echo "(7)  POSTGRESQL   ... FAILED"
fi
if [ -f $CFENGINE_LIB/libmysqlclient.a ]; then
 echo "(8)  MYSQL        ... OK"
else
 echo "(8)  MYSQL        ... FAILED"
fi
if [ -f $CFENGINE_LIB/libldap.so ]; then
 echo "(9)  OPENLDAP     ... OK"
else
 echo "(9)  OPENLDAP     ... FAILED"
fi
if [ -f $CFENGINE_LIB/libxml2.a ]; then
 echo "(10) LIBXML2      ... OK"
else
 echo "(10) LIBXML2     ... FAILED"
fi
if [ -f $CFENGINE_LIB/liblmdb.so ]; then
 echo "(11) LMDB         ... OK"
else
 echo "(11) LMDB         ... FAILED"
fi
if [ -f $CFENGINE_LIB/fipscanister.o ]; then
 echo "(26) FIPS 140-2   ... OK"
else
 echo "(26) FIPS 140-2   ... FAILED"
fi
if [ -f $CFENGINE_LIB/libyaml.so ]; then
 echo "(27) YAML         ... OK"
else
 echo "(27) YAML         ... FAILED"
fi