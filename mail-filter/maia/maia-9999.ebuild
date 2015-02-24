# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

inherit depend.php eutils webapp user git-2

DESCRIPTION="Maia Mailguard is a Web based frontend to control virus scanners and spam filters"
HOMEPAGE="https://github.com/technion/maia_mailguard"

EGIT_REPO_URI="git://github.com/technion/maia_mailguard.git"
SRC_URI=""

MY_PV=${PV/a//}
MY_S=${WORKDIR}/${PN}-${MY_PV}

# SLOT="0"
LICENSE="GPL-2"
KEYWORDS="~x86 ~amd64"
IUSE="apache crypt mysql postgres"

DEPEND=">=sys-apps/sed-4
	>=dev-lang/perl-5.8.2"

RDEPEND=" >=sys-apps/coreutils-5.0-r3
	app-arch/gzip
	app-arch/bzip2
	app-arch/arc
	app-arch/cabextract
	app-arch/freeze
	app-arch/lha
	app-arch/unarj
	app-arch/unrar
	app-arch/zoo
	mail-filter/spamassassin
	virtual/mta
	virtual/perl-Archive-Tar
	>=dev-perl/Archive-Zip-1.14
	dev-perl/Convert-TNEF
	>=dev-perl/Convert-UUlib-1.06
	>=dev-perl/DBI-1.40
	dev-perl/IO-stringy
	virtual/perl-MIME-Base64
	dev-perl/MIME-tools
	>=dev-perl/net-server-0.93
	dev-perl/Template-Toolkit
	>=virtual/perl-Time-HiRes-1.49
	dev-perl/Unix-Syslog
	dev-perl/Data-UUID
	>=dev-perl/MailTools-1.58
	>=perl-core/libnet-1.21
	>=perl-core/IO-Compress-2.0.20
	crypt? ( dev-perl/Crypt-Blowfish
			dev-perl/crypt-cbc )
	apache? ( www-servers/apache
			>=virtual/httpd-php-4.0.2
			dev-php/PEAR-Net_POP3
			>=dev-php/PEAR-Net_IMAP-1.0.3
			dev-php/PEAR-Net_SMTP
			dev-php/PEAR-DB
			dev-php/PEAR-Pager
			dev-php/PEAR-Log
			>=dev-php/PEAR-Mail_Mime-1.3.0
			>=dev-php/smarty-2.6.14
			dev-libs/libmcrypt )
	mysql? ( >=dev-db/mysql-4.0.1
			dev-perl/DBD-mysql )
	postgres? ( >=dev-db/libpq-8.0
			>=dev-perl/DBD-Pg-1.31 )"


pkg_setup() {
	if use apache
	then
		require_php_with_use wddx
	fi
	webapp_pkg_setup
	enewgroup amavis
	enewuser amavis -1 -1 /var/lib/amavis amavis
}

src_install() {
	webapp_src_preinst
	# Install maia scripts
	cd ${MY_S}/scripts
	exeinto /usr/bin
	exeopts -oamavis -gamavis -m0700
	doexe  *.pl

	cd ${MY_S}
	exeinto /usr/sbin
	exeopts -oamavis -gamavis -m0700
	doexe maiad

	# Config files
	cd ${MY_S}
	dodir /var/run/amavis
	insinto /etc
	cp maia.conf.dist maia.conf
	doins maia.conf
	sed "s:^\$script_dir = [^;]*;:\$script_dir = \"/usr/bin\";: "\
		/etc/maia.conf
	sed "s:^\$#$key_file = [^;]*;:\$#key_file = \"/var/amavis/maia.key\";: "\
		/etc/maia.conf
	cp amavisd.conf.dist amavisd.conf
	doins maia.conf
	sed "s:/var/amavisd:/var/amavis:g" /etc/amavisd.conf
	sed "s:^\$MYHOME   = [^;]*;:\$MYHOME   = \"/var/amavis\";  : "\
		/etc/amavisd.conf
	sed "s:^# \$pid_file  = [^;]*;:\$pid_file = \"/var/run/amavis/amavisd.pid\";  : "\
		/etc/amavisd.conf
	sed "s:^# \$lock_file = [^;]*;:\$lock_file = \"/var/run/amavis/amavisd.lock\";  : "\
		/etc/amavisd.conf
	sed "s:/var/amavisd/clamd.sock:/var/run/clamav/clamd.sock:g" /etc/amavisd.conf

	if [ "$(dnsdomainname)" = "(none)" ] ; then
		sed "s:^#\\?\\\$mydomain[^;]*;:\$mydomain = '$(hostname)';:" \
			/etc/amavisd.conf
	else
		sed "s:^#\\?\\\$mydomain[^;]*;:\$mydomain = '$(dnsdomainname)';:" \
			/etc/amavisd.conf
	fi

	keepdir /var/run/amavis/
	keepdir /var/amavis/
	keepdir /var/amavis/tmp
	keepdir /var/amavis/db
	keepdir /var/amavis/templates

	cd ${MY_S}
	dodoc LICENSE.txt README.md maia-mysql.sql maia-pgsql.sql
	# webapp-config is not yet ready to deal with this
	# webapp_sqlscript mysql 	maia-mysql.sql
	# webapp_sqlscript postgres	maia-pgsql.sql


	# Also install full amavisd-new source as documentation
	tar cvf amavisd-new-2.2.1.tgz reference/amavisd-new-2.2.1/
	dodoc amavisd-new-2.2.1.tgz

	insinto /var/amavis/templates
	cd ${MY_S}/templates
	doins *.tpl

	if use apache
	then
		cd ${MY_S}/php
		cat config.php.dist |\
			sed 's:\t// \$smarty_path = [^;]*;:\t\$smarty_path = \"/usr/share/php/smarty/\";:' \
			> config.php
		cp -R * ${D}/${MY_HTDOCSDIR}

		cd ${WORKDIR}/fr
		mkdir ${D}/${MY_HTDOCSDIR}/locale/fr
		cp *.php  ${D}/${MY_HTDOCSDIR}/locale/fr

		webapp_configfile ${MY_HTDOCSDIR}/config.php
		webapp_hook_script ${FILESDIR}/reconfig-${PV}
		webapp_postinst_txt en ${FILESDIR}/postinstall-en.txt
	fi

	newinitd "${FILESDIR}/maia.rc" maia-amavisd
	webapp_src_install
}

pkg_postinst() {
	einfo "The first stage of the installation is done. Now you need to setup "
	einfo "your virtual hosts via webapp-config"
	einfo "Please read man webapp-config for a detailed description of the"
	einfo "process and some examples"
	einfo ""
	einfo "If you want to have crypted database, do "
	einfo "generate-key.pl > /var/amavis/maia.key"
	einfo "and edit /etc/amavisd.conf and /etc/maia.conf and via web interface"

	chmod o-rwx /etc/amavisd.conf
	chown root:amavis /etc/amavisd.conf
	chown -R amavis:amavis /var/amavis
	chown -R amavis:amavis /var/run/amavis
}

