#!/bin/sh

# compile without ldap
# all dependencies should be in /var/cfengine already
# CFEngine tarball in $SOURCE_DIR

export LDFLAGS="-L/var/cfengine/lib -R/var/cfengine/lib" 
export CFLAGS=-I/var/cfengine/include
export LD_LIBRARY_PATH=/var/cfengine/lib
export LD_RUN_PATH=/var/cfengine/lib

MAINTAINER=contact@cfengineers.net
ARCH=`machine -a`

BUILD_DIR=/root/tgzroot
TGZ_PACKAGE=$BUILD_DIR/tgz_package
SOURCE_DIR=/usr/local/src
CORE=3.7.0
REV=1

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
 ./configure --prefix=/var/cfengine --with-lmdb=/var/cfengine --with-pcre=/var/cfengine --with-openssl=/var/cfengine --with-libyaml=/var/cfengine --enable-shared LDFLAGS=-L/var/cfengine/lib CPPFLAGS=-I/var/cfengine/include && LD_LIBRARY_PATH=/usr/local/lib gmake CC="gcc -R /var/cfengine/lib" && LD_LIBRARY_PATH=/usr/local/lib gmake install && LD_LIBRARY_PATH=/usr/local/lib gmake install DESTDIR=/tmp/xxx
 rm -rf $SOURCE_DIR/cfengine-$CORE
else
 echo ""
 echo "No $SOURCE_DIR/cfengine-$CORE-$REV.tar.gz, bail out"
 echo ""
 exit 0
fi

# create additional files for packaging
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
cat >> pkg-plist << EOF
var/cfengine/lib/libpq.so.5.2
var/cfengine/lib/libxml2.so.11.2
var/cfengine/lib/liblmdb.so
var/cfengine/lib/libpcre.so.3.4
var/cfengine/lib/libssl.so.0.9.8
var/cfengine/lib/libcrypto.so.0.9.8
var/cfengine/lib/libyaml.so.2.3
var/cfengine/lib/libyaml-0.so.2.3
var/cfengine/rc.d/cfengine3
@exec /bin/mkdir -p /var/cfengine/bin /var/cfengine/rc.d /var/cfengine/software_updates
@exec cp -f /var/cfengine/rc.d/cfengine3 /etc/rc.d
@exec /bin/chmod 555 /etc/rc.d/cfengine3
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
@exec if [ ! -f /etc/rc.conf.local ]; then touch /etc/rc.conf.local; fi
@exec grep -q "pkg_scripts=cfengine3" /etc/rc.conf.local || echo "pkg_scripts=cfengine3" >> /etc/rc.conf.local
@unexec ps waux | grep cf-execd > /dev/null && /usr/bin/pkill -9 cf-execd || true
@unexec ps waux | grep cf-monitord > /dev/null && /usr/bin/pkill -9 cf-monitord || true
@unexec ps waux | grep cf-serverd > /dev/null && /usr/bin/pkill -9 cf-serverd || true
@unexec /bin/rm -rf /var/cfengine/rc.d
@unexec /bin/rm -f /etc/rc.d/cfengine3
@unexec /bin/rm -f /usr/local/sbin/cf-agent
@unexec /bin/rm -f /usr/local/sbin/cf-execd
@unexec /bin/rm -f /usr/local/sbin/cf-key
@unexec /bin/rm -f /usr/local/sbin/cf-monitord
@unexec /bin/rm -f /usr/local/sbin/cf-promises
@unexec /bin/rm -f /usr/local/sbin/cf-runagent
@unexec /bin/rm -f /usr/local/sbin/cf-serverd
@unexec grep -q "pkg_scripts=cfengine3" /etc/rc.conf.local && sed '/cfengine3/d' /etc/rc.conf.local > /tmp/rc.conf.local.tmp && cp -f /tmp/rc.conf.local.tmp /etc/rc.conf.local
EOF

# startup script
cat > /var/cfengine/rc.d/cfengine3 << EOF
#!/bin/sh

#
# Author: Nakarin Phooripoom
# email:  contact@cfengineers.net
#

ldconfig -m /var/cfengine/lib

CFPROMISES=/var/cfengine/bin/cf-promises
CFEXECD=/var/cfengine/bin/cf-execd
CFSERVD=/var/cfengine/bin/cf-serverd
CFMOND=/var/cfengine/bin/cf-monitord

ECHO=/bin/echo
KILL=/bin/kill
PKILL=/usr/bin/pkill
GREP=/usr/bin/grep
PS=/bin/ps

case "\$1" in
        start)
                \$CFPROMISES > /dev/null
                RET=\$?
                if [ \$RET = "0" ]; then
                        \$ECHO "Starting cf-execd ..."
                        \$CFEXECD
                        \$ECHO "Starting cf-serverd ..."
                        \$CFSERVD
                        \$ECHO "Starting cf-monitord ..."
                        \$CFMOND
                        sleep 2
                        \$0 status
                fi
        ;;
        stop)
                \$PS waux | \$GREP -v grep | \$GREP -q cfengine
                RET=\$?
                if [ \$RET = "0" ]; then
                        \$ECHO "Shuting down all CFEngine processes ..."
                        \$PKILL cf- && sleep 2
                        \$0 status
                fi
        ;;
        status)
                \$PS waux | \$GREP -v grep | \$GREP -q cf-execd
                RET=\$?
                if [ \$RET = "0" ]; then
                        \$ECHO "cf-execd    : running"
                else
                        \$ECHO "cf-execd    : stopped"
                fi
                \$PS waux | \$GREP -v grep | \$GREP -q cf-serverd
                RET=\$?
                if [ \$RET = "0" ]; then
                        \$ECHO "cf-serverd  : running"
                else
                        \$ECHO "cf-serverd  : stopped"
                fi
                \$PS waux | \$GREP -v grep | \$GREP -q cf-monitord
                RET=\$?
                if [ \$RET = "0" ]; then
                        \$ECHO "cf-monitord : running"
                else
                        \$ECHO "cf-monitord : stopped"
                fi
        ;;
        restart|reload|force-reload)
                \$0 stop
                sleep 5
                \$0 start
        ;;
        *)
                N=/etc/rc.d/cfengine3
                echo "Usage: \$N {start|stop|status|restart|reload|force-reload}" >&2
                exit 1
        ;;
esac
EOF

# Pack it up
cd $TGZ_PACKAGE
/usr/sbin/pkg_create -f $TGZ_PACKAGE/pkg-plist -d $TGZ_PACKAGE/pkg-descr -A $ARCH -D COMMENT="CFEngine 3: An automated suite tools for data centers!!!" -D MAINTAINER=$MAINTAINER -D FULLPKGPATH=sysutils/cfengine3 -p "/" cfengine-community-${CORE}p${REV}.tgz

# Notify
if [ -f $TGZ_PACKAGE/cfengine-community-${CORE}p${REV}.tgz ]; then
 echo ""
 echo "Created in $TGZ_PACKAGE/cfengine-community-${CORE}p${REV}.tgz"
 echo ""
else
 echo "Failed to build $CORE-$REV"
fi

# clean up
rm -f /etc/rc.d/cfengine3
rm -rf /tmp/xxx