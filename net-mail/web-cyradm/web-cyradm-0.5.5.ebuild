# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# Source: http://bugs.gentoo.org/show_bug.cgi?id=65318
# Submitted-By: SteveB
# Reviewed-By: wrobel 2005-12-19

inherit eutils webapp depend.php

MY_PV="${PV}"

DESCRIPTION="Web-based application that glues topnotch mailing technologies like cyrus-imap and postfix together."
SRC_URI="http://www.web-cyradm.org/web-cyradm-svn-0.5.5.tar.gz"
HOMEPAGE="http://www.web-cyradm.org/"

LICENSE="GPL-2"
KEYWORDS="~x86"
IUSE="mysql postgres pam"

RDEPEND=">=net-mail/cyrus-imapd-2.2.12
	>=dev-php/PEAR-DB-1.7.6
	pam? ( mysql? ( >=sys-auth/pam_mysql-0.5 )
		!mysql? ( postgres? ( >=sys-auth/libnss-pgsql-1.0.0 ) )
		!mysql? ( !postgres? ( >=sys-auth/pam_mysql-0.5 ) ) )
	virtual/mta
	virtual/httpd-cgi"

# PHP5 only supported in SVN snapshots
need_php4_httpd

S=${WORKDIR}/${PN}-svn-${MY_PV}

pkg_setup() {
	local multiple_dbs="0"
	local supported_dbs="mysql postgres"
	local foo
	for foo in ${supported_dbs}; do
		if use ${foo}; then
			let multiple_dbs="((multiple_dbs + 1 ))"
			einfo " ${foo} database support in your USE flags."
		fi
	done
	if [[ "${multiple_dbs}" -eq "0" ]] ; then
		ewarn
		ewarn "You have no database backend active in your USE flags."
		ewarn "Will default to MySQL as your ${PN} database backend."
		ewarn "If you want to use PostgreSQL database backend; hit Control-C now,"
		ewarn "add postgres to your USE flags and emerge again."
		ewarn
		epause 5
	elif [[ "${multiple_dbs}" -gt "1" ]] ; then
		ewarn
		ewarn "You have multiple database backends active in your USE flags."
		ewarn "Will default to MySQL as your ${PN} database backend."
		ewarn "If you want to use another database backend; hit Control-C now,"
		ewarn "disable mysql in your USE flags and emerge again."
		ewarn
		epause 5
	else
		einfo "Using ${foo} as the database backend."
	fi

	if use mysql  ; then
		local phpflags="mysql"
	elif use postgres ; then
		local phpflags="postgres"
	else
		local phpflags="mysql"
	fi
	require_php_with_use ${phpflags}

	webapp_pkg_setup
}

src_unpack() {
	unpack ${A}
	cd "${S}"

	# Remove .cvs* files and CVS directories
	ecvs_clean

	# Rename the config file
	mv -f config/conf.php.dist config/conf.php

	# http://www.shaolinux.org/web-cyradm-0.5.4-1.FQUN.20041109.diff
	use pam || epatch "${FILESDIR}"/${PN}-${MY_PV}.FQUN.20041109.diff
}

src_install() {
	webapp_src_preinst

	local docs="ChangeLog README README.translations TO-BE-DONE doc/Postfix-Cyrus-Web-cyradm-HOWTO.txt"
	dodoc ${docs}
	dohtml -r doc/html/*
	rm -rf ${docs} COPYRIGHT INSTALL doc/

	einfo "Installing main files"
	cp *.php "${D}"/${MY_HTDOCSDIR}
	cp -R css images lib locale config "${D}"/${MY_HTDOCSDIR}

	# install the SQL scripts available to us
	# Because of limitations in the webapp ECLASS we need to merge the
	# insertuser SQL scripts into one file
	if use mysql || ( ! use mysql && ! use postgres ) ; then
		cp scripts/insertuser_mysql.sql "${T}"/merged_mysql.sql
		echo >>"${T}"/merged_mysql.sql
		sed -n "s:^create database:USE:gIp" scripts/insertuser_mysql.sql >>"${T}"/merged_mysql.sql
		echo >>"${T}"/merged_mysql.sql
		cat scripts/create_mysql.sql >>"${T}"/merged_mysql.sql
		webapp_sqlscript mysql "${T}"/merged_mysql.sql
		webapp_sqlscript mysql scripts/upgrade-0.5.3-to-0.5.4_mysql.sql 0.5.3
	elif use postgres; then
		cp scripts/insertuser_pgsql.sql "${T}"/merged_pgsql.sql
		echo >>"${T}"/merged_pgsql.sql
		sed -n "s:^create database:USE:gIp" scripts/insertuser_pgsql.sql >>"${T}"/merged_pgsql.sql
		echo >>"${T}"/merged_pgsql.sql
		cat scripts/create_pgsql.sql >>"${T}"/merged_pgsql.sql
		webapp_sqlscript pgsql "${T}"/merged_pgsql.sql
		webapp_sqlscript pgsql scripts/upgrade-0.5.3-to-0.5.4_pgsql.sql 0.5.3
	fi

	webapp_serverowned ${MY_HTDOCSDIR}
	webapp_configfile ${MY_HTDOCSDIR}/config/conf.php
	webapp_postinst_txt en "${FILESDIR}"/postinstall-en.txt

	webapp_src_install
}
