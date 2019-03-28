#!/bin/sh

# prepare shell environments
export LDFLAGS="-L/var/cfengine/lib -R/var/cfengine/lib" 
export CFLAGS="-I/var/cfengine/include"
export LD_LIBRARY_PATH=/var/cfengine/lib
export LD_RUN_PATH=/var/cfengine/lib

# where tarballs located
SOURCE_DIR=/usr/local/src
WORKDIR=/root/txzroot
MANIFEST=$WORKDIR/manifest
RESDIR=/root/ready_to_rock
VER=3.7.2
REV=1
UNAMEM=`uname -m`
if [ $UNAMEM = "i386" ]; then ARCH=x86:32; fi
if [ $UNAMEM = "amd64" ]; then ARCH=x86:64; fi 

rm -f /var/cfengine/share/doc/cfengine/examples/*
rm -rf /tmp/xxx

# start compiling CFEngine
cd $SOURCE_DIR
tar xvfz cfengine-$VER.tar.gz
cd cfengine-$VER
./configure --with-lmdb=/var/cfengine --with-pcre=/var/cfengine --with-openssl=/var/cfengine LDFLAGS=-L/var/cfengine/lib CPPFLAGS=-I/var/cfengine/include && gmake CC="gcc -R /var/cfengine/lib" && gmake install && gmake install DESTDIR=/tmp/xxx

# prepare configuration files for pkg_create
if [ ! -d $MANIFEST ]; then mkdir -p $MANIFEST; fi
cd $MANIFEST
# manifest file
cat > +MANIFEST << EOF
name: cfengine-community
version: ${VER}_${REV}
origin: sysutils/cfengine-community
comment: CFEngine 3 Enterprise: An automated suite tools for data centres.
arch: freebsd:10:$ARCH
www: https://cfengine.com
maintainer: contact@cfengineers.net
prefix: /
licenses: [GPLv3]
flatsize: 6291456
desc: |-
  CFEngine is an automated suite of programs for configuring and 
  maintaining Unix-like computers. It has been used on computing arrays 
  of between 1 and 30,000 computers since 1993 by a wide range of 
  organizations. CFEngine is supported by active research and was the 
  first autonomic, hands-free management system for Unix-like operating
  systems. CFEngine is an autonomic maintenance system not merely a
  change management roll-out tool. CFEngine has a history of security
  and adaptability.
EOF

# pkg-plist file
cd $WORKDIR
echo "@comment pkg-plist,v 1.00 2014/06/21" > pkg-plist
echo "@comment ORIGIN:sysutils/cfengine-community" >> pkg-plist
find /tmp/xxx -type f | sort | cut -d'/' -f4- | grep -v libpromises.la >> pkg-plist
cat >> pkg-plist << EOF
var/cfengine/lib/libpq.so.5
var/cfengine/lib/libxml2.so.11
var/cfengine/lib/liblmdb.so
var/cfengine/lib/libpcre.so.3
var/cfengine/lib/libssl.so.1.0.0
var/cfengine/lib/libcrypto.so.1.0.0
var/cfengine/lib/libyaml-0.so.2
var/cfengine/rc.d/cfengine3.sh
@exec rm -f /usr/local/lib/libpromises.*
@exec if [ ! -d /usr/local/etc/rc.d ]; then mkdir -p /usr/local/etc/rc.d; fi
@exec /bin/cp -f /var/cfengine/rc.d/cfengine3.sh /usr/local/etc/rc.d
@exec /bin/ln -s /var/cfengine/bin/cf-agent /usr/local/sbin
@exec /bin/ln -s /var/cfengine/bin/cf-execd /usr/local/sbin
@exec /bin/ln -s /var/cfengine/bin/cf-key /usr/local/sbin
@exec /bin/ln -s /var/cfengine/bin/cf-monitord /usr/local/sbin
@exec /bin/ln -s /var/cfengine/bin/cf-promises /usr/local/sbin
@exec /bin/ln -s /var/cfengine/bin/cf-runagent /usr/local/sbin
@exec /bin/ln -s /var/cfengine/bin/cf-serverd /usr/local/sbin
@exec /bin/chmod 0755 /usr/local/etc/rc.d/cfengine3.sh
@exec /bin/chmod -R 0755 /var/cfengine/lib
@exec /bin/chmod -R 0644 /var/cfengine/lib/lib*
@exec /bin/chmod -R 0755 /var/cfengine/bin
@exec /sbin/ldconfig -m /var/cfengine/lib
@exec /usr/bin/touch /var/cfengine/cfagent.`hostname`.log
@exec if [ ! -f /var/cfengine/ppkeys/localhost.priv ]; then /var/cfengine/bin/cf-key; fi
@exec if [ -f /var/cfengine/inputs/promises.cf ]; then /var/cfengine/bin/cf-execd; fi
@unexec /bin/pkill -9 cf-execd > /dev/null 2>&1 || true
@unexec /bin/pkill -9 cf-monitord > /dev/null 2>&1 || true
@unexec /bin/pkill -9 cf-serverd > /dev/null 2>&1 || true
@unexec /bin/rm -f /usr/local/etc/rc.d/cfengine3.sh > /dev/null 2>&1
@unexec /bin/rm -f /usr/local/sbin/cf-agent > /dev/null 2>&1
@unexec /bin/rm -f /usr/local/sbin/cf-execd > /dev/null 2>&1
@unexec /bin/rm -f /usr/local/sbin/cf-key > /dev/null 2>&1
@unexec /bin/rm -f /usr/local/sbin/cf-know > /dev/null 2>&1
@unexec /bin/rm -f /usr/local/sbin/cf-hub > /dev/null 2>&1
@unexec /bin/rm -f /usr/local/sbin/cf-monitord > /dev/null 2>&1
@unexec /bin/rm -f /usr/local/sbin/cf-promises > /dev/null 2>&1
@unexec /bin/rm -f /usr/local/sbin/cf-report > /dev/null 2>&1
@unexec /bin/rm -f /usr/local/sbin/cf-runagent > /dev/null 2>&1
@unexec /bin/rm -f /usr/local/sbin/cf-serverd > /dev/null 2>&1
EOF

# create start-up script
if [ ! -d /var/cfengine/rc.d ]; then mkdir /var/cfengine/rc.d; fi
cat > /var/cfengine/rc.d/cfengine3.sh << EOF
#!/bin/sh
#
# REQUIRE: networking syslog
# PROVIDE: cfengine3
#
# Add the following line to /etc/rc.conf to enable cfengine:
#
# cfengine3_enable="YES"
#

. /etc/rc.subr

name="cfengine3"
components="cf-execd cf-agent cf-serverd cf-monitord cf-runagent"
command="/var/cfengine/bin/cf-execd"
rcvar=\`set_rcvar\`

# There is a bug in /etc/rc.subr which destroys the command name if the
# command has a '-' in it (the bug is in the eval which creates the
# _override_command variable.  So we write our own kludgy cfengine3_start
_saved_command="/var/cfengine/bin/cf-execd"

stop_cmd="cfengine3_stop"
start_cmd="cfengine3_start"

cfengine3_start()
{
	if [ ! -x \${_saved_command} ]; then
		warn "cannot run \$_saved_command"
		return 1
	fi
	\$_saved_command
}

cfengine3_stop()
{
	echo "Stopping cfengine components: \${components}"
	pkill \${components}
}

load_rc_config "\$name"
cfengine3_enable=\${cfengine3_enable-"NO"}

run_rc_command "\$1"
EOF

# start packaging CFEngine
cd $WORKDIR
/usr/sbin/pkg create -f txz -p $WORKDIR/pkg-plist -m $MANIFEST -r "/"
if [ ! -d $RESDIR ]; then mkdir -p $RESDIR; fi
cp -f $WORKDIR/cfengine-community-${VER}_${REV}.txz $RESDIR

# clear up
cd
rm -rf $SOURCE_DIR/cfengine-$VER
rm -rf /tmp/xxx
