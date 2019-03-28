#!/bin/sh

# compile without ldap
# all dependencies should be in /var/cfengine already
# CFEngine tarball in $SOURCE_DIR

export LDFLAGS="-L/var/cfengine/lib -R/var/cfengine/lib" 
export CFLAGS=-I/var/cfengine/include
export LD_LIBRARY_PATH=/var/cfengine/lib
export LD_RUN_PATH=/var/cfengine/lib

BUILD_DIR=/root/tgzroot
TGZ_PACKAGE=$BUILD_DIR/tgz_package
SOURCE_DIR=/usr/local/src
CORE=3.7.0
REV=1

# pkg-info details
MAINTAINER=contact@cfengineers.net
ARCH=`uname -m`
OS_VER=`uname -r`
if [ "$ARCH" = "amd64" ]; then
 ARCH=x86_64
fi
if [ "$OS_VER" = "4.0" ]; then
 GCC=gcc-4.1.2
 PKG_TOOL=20101212
fi
if [ "$OS_VER" = "4.0.1" ]; then
 GCC=gcc-4.1.2
 PKG_TOOL=20101212
fi
if [ "$OS_VER" = "5.0" ]; then
 GCC=gcc-4.1.3
 PKG_TOOL=20100204
fi
if [ "$OS_VER" = "5.0.1" ]; then
 GCC=gcc-4.1.3
 PKG_TOOL=20100204
fi
if [ "$OS_VER" = "5.0.2" ]; then
 GCC=gcc-4.1.3
 PKG_TOOL=20100204
fi
if [ "$OS_VER" = "5.1" ]; then
 GCC=gcc-4.1.3
 PKG_TOOL=20100204
fi
if [ "$OS_VER" = "5.2" ]; then
 GCC=gcc-4.1.3
 PKG_TOOL=20100204
fi
if [ "$OS_VER" = "5.2.2" ]; then
 GCC=gcc-4.1.3
 PKG_TOOL=20100204
fi
if [ "$OS_VER" = "6.0" ]; then
 GCC=gcc-4.5.3
 PKG_TOOL=20100204
fi
if [ "$OS_VER" = "6.1.4" ]; then
 GCC=gcc-4.5.3
 PKG_TOOL=20100204
fi
if [ "$OS_VER" = "6.1.5" ]; then
 GCC=gcc-4.5.3
 PKG_TOOL=20100204
fi

# preparing directories
if [ ! -d "$TGZ_PACKAGE" ]; then
 mkdir -p $TGZ_PACKAGE
fi
if [ ! -d "/var/cfengine/rc.d" ]; then
 mkdir -p /var/cfengine/rc.d
fi

# compile core
if [ -f $SOURCE_DIR/cfengine-$CORE.tar.gz ]; then
 cd $SOURCE_DIR
 tar xvfz cfengine-$CORE.tar.gz
 cd $SOURCE_DIR/cfengine-$CORE
 ./configure --prefix=/var/cfengine --with-lmdb=/var/cfengine --with-pcre=/var/cfengine --with-openssl=/var/cfengine LDFLAGS=-L/var/cfengine/lib CPPFLAGS=-I/var/cfengine/include
 # This is for cfengine-community-3.6.0
 ##sed "s/1.13/1.14/g" < Makefile > /tmp/Makefile
 ##cp -f /tmp/Makefile $SOURCE_DIR/cfengine-$CORE/Makefile
 #
 gmake CC="gcc -R /var/cfengine/lib" && gmake install && gmake install DESTDIR=/tmp/xxx
 rm -rf $SOURCE_DIR/cfengine-$CORE
else
 echo ""
 echo "No $SOURCE_DIR/cfengine-$CORE.tar.gz, bail out"
 echo ""
 exit 0
fi

# create additional files for packaging
# pkg-comment
cat > $TGZ_PACKAGE/pkg-comment << EOF
CFEngine 3: An automated suite tools for data centers!!!
EOF
# pkg-description
cat > $TGZ_PACKAGE/pkg-descr << EOF
CFEngine is an automated suite of programs for configuring and maintaining 
Unix-like computers. It has been used on computing arrays of between 
1 and 30,000 computers since 1993 by a wide range of organizations. 
CFEngine is supported by active research and was the first autonomic, 
hands-free management system for Unix-like operating systems. 
CFEngine is an autonomic maintenance system not merely a change management 
roll-out tool. CFEngine has a history of security and adaptability.

WWW: https://cfengine.com
EOF
# pkg-plist
cd $TGZ_PACKAGE
echo "@comment pkg-plist,v 1.00 2014/06/21" > pkg-plist
echo "@comment ORIGIN:sysutils/cfengine-community" >> pkg-plist
find /tmp/xxx -type f | sort | cut -d'/' -f4- | grep -v libpromises.la >> pkg-plist
cat >> $TGZ_PACKAGE/pkg-plist << EOF
var/cfengine/rc.d/cfengine3.sh
var/cfengine/lib/libpromises.so.3
var/cfengine/lib/liblmdb.so
var/cfengine/lib/libpcre.so.3
var/cfengine/lib/libpcre.so.3.4
var/cfengine/lib/libssl.so.0.9.8
var/cfengine/lib/libcrypto.so.0.9.8
var/cfengine/lib/libpq.so.5
var/cfengine/lib/libpq.so.5.2
var/cfengine/lib/libxml2.so.11
var/cfengine/lib/libxml2.so.11.2
var/cfengine/lib/libyaml-0.so.2
var/cfengine/lib/libyaml-0.so.2.3
@exec /bin/mkdir -p /var/cfengine/bin /var/cfengine/rc.d
@exec /bin/cp -f /var/cfengine/rc.d/cfengine3.sh /usr/local/etc/rc.d
@exec /bin/chmod 755 /var/cfengine/lib
@exec /bin/chmod 644 /var/cfengine/lib/lib*
@exec /bin/chmod -R 755 /var/cfengine/bin
@exec /sbin/ldconfig -m /var/cfengine/lib || true
@exec /usr/bin/touch /var/cfengine/cfagent.`hostname`.log
@exec /bin/mkdir -p /usr/local/sbin || true
@exec ln -s /var/cfengine/bin/cf-agent /usr/local/sbin/cf-agent || true
@exec ln -s /var/cfengine/bin/cf-execd /usr/local/sbin/cf-execd || true
@exec ln -s /var/cfengine/bin/cf-key /usr/local/sbin/cf-key || true
@exec ln -s /var/cfengine/bin/cf-monitord /usr/local/sbin/cf-monitord || true
@exec ln -s /var/cfengine/bin/cf-promises /usr/local/sbin/cf-promises || true
@exec ln -s /var/cfengine/bin/cf-runagent /usr/local/sbin/cf-runagent || true
@exec ln -s /var/cfengine/bin/cf-serverd /usr/local/sbin/cf-serverd || true
@exec if [ ! -f /var/cfengine/ppkeys/localhost.pub ]; then /var/cfengine/bin/cf-key; fi
@exec if [ -f /var/cfengine/inputs/promises.cf ]; then /var/cfengine/bin/cf-execd; fi
@unexec ps waux | grep cf-execd > /dev/null && /usr/bin/pkill -9 cf-execd || true
@unexec ps waux | grep cf-monitord > /dev/null && /usr/bin/pkill -9 cf-monitord || true
@unexec ps waux | grep cf-serverd > /dev/null && /usr/bin/pkill -9 cf-serverd || true
@unexec /bin/rm -f /usr/local/etc/rc.d/cfengine3.sh
@unexec /bin/rm -f /usr/local/sbin/cf-agent
@unexec /bin/rm -f /usr/local/sbin/cf-execd
@unexec /bin/rm -f /usr/local/sbin/cf-key
@unexec /bin/rm -f /usr/local/sbin/cf-monitord
@unexec /bin/rm -f /usr/local/sbin/cf-promises
@unexec /bin/rm -f /usr/local/sbin/cf-runagent
@unexec /bin/rm -f /usr/local/sbin/cf-serverd
EOF

# pkg-info
cat > $TGZ_PACKAGE/pkg-info << EOF
ABI=
BUILD_DATE=2013-09-03 00:00:00 +0000
BUILD_HOST=
CATEGORIES=sysutil
CC_VERSION=$GCC
CFLAGS=-O2 -I/var/cfengine/include
CMAKE_ARGS=
CONFIGURE_ARGS= --prefix=/var/cfengine --with-lmdb=/var/cfengine --with-pcre=/var/cfengine --with-openssl=/var/cfengine LDFLAGS=-L/var/cfengine/lib CPPFLAGS=-I/var/cfengine/include && gmake CC="gcc -R /var/cfengine/lib" 
CONFIGURE_ENV=
CPPFLAGS= -I/var/cfengine/include
FFLAGS=-O
HOMEPAGE=https://cfengine.com
LDFLAGS= -L/var/cfengine/lib -Wl,-R/var/cfengine/lib -Wl
LICENSE=COSL
LOCALBASE=/
MACHINE_ARCH=$ARCH
MACHINE_GNU_ARCH=$ARCH
MAINTAINER=$MAINTAINER
NO_BIN_ON_CDROM=
NO_BIN_ON_FTP=
NO_SRC_ON_CDROM=
NO_SRC_ON_FTP=
OBJECT_FMT=ELF
OPSYS=NetBSD
OS_VERSION=$OS_VER
PKGINFODIR=info
PKGMANDIR=man
PKGPATH=sysutil/cfengine-community
PKGTOOLS_VERSION=$PKG_TOOL
PKG_SYSCONFBASEDIR=/
PKG_SYSCONFDIR=/
REQUIRES=
REQUIRES=
RESTRICTED=
_PLIST_IGNORE_FILES=
_USE_DESTDIR=no
EOF

# start-up script
cat > /var/cfengine/rc.d/cfengine3.sh << EOF
#!/bin/sh
#
# REQUIRE: network syslogd
# PROVIDE: cfengine3
#
# Add the following line to /etc/rc.conf to enable cfengine:
#
# cfengine3="YES"
#

. /etc/rc.subr

name="cfengine3"
rcvar=${name}

components="cf-execd cf-agent cf-serverd cf-monitord"
command="/var/cfengine/bin/cf-execd"

stop_cmd="cfengine3_stop"
start_cmd="cfengine3_start"
restart_cmd="cfengine3_stop ; cfengine3_start"

cfengine3_start()
{
    if [ ! -x \${command} ]; then
        warn "cannot run \${command}"
                return 1
        fi
        ${command}
}

cfengine3_stop()
{
        echo "Stopping cfengine components: \${components}"
        pkill \${components}
}

load_rc_config \${name}
run_rc_command "\$1"
EOF

# Pack it up
cd $TGZ_PACKAGE
/usr/sbin/pkg_create -B $TGZ_PACKAGE/pkg-info -f $TGZ_PACKAGE/pkg-plist -c $TGZ_PACKAGE/pkg-comment -d $TGZ_PACKAGE/pkg-descr -p "/" cfengine-community-${CORE}nb${REV}.tgz

# Notify
if [ -f $TGZ_PACKAGE/cfengine-community-${CORE}nb${REV}.tgz ]; then
 mkdir -p /root/ready_to_rock
 cp $TGZ_PACKAGE/cfengine-community-${CORE}nb${REV}.tgz /root/ready_to_rock
 echo ""
 echo "Created in $TGZ_PACKAGE/cfengine-community-${CORE}nb${REV}.tgz"
 echo ""
else
 echo "Failed to build $CORE-$REV"
fi

rm -rf /tmp/xxx
