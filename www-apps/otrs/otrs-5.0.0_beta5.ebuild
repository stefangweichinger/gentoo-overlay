# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit eutils confutils user systemd

MY_PV="${PV/_beta/.beta}"
MY_P="${PN}-${MY_PV}"

DESCRIPTION="OTRS is an Open source Ticket Request System"
HOMEPAGE="http://otrs.org/"
SRC_URI="http://ftp.otrs.org/pub/${PN}/${MY_P}.tar.bz2"

LICENSE="AGPL-3"
KEYWORDS="~amd64 ~x86"
IUSE="apache2 fastcgi +gd ldap mod_perl +mysql pdf postgres soap"
SLOT="0"

RDEPEND="dev-perl/Apache-Reload
	dev-perl/Archive-Zip
	dev-perl/Authen-SASL
	dev-perl/Crypt-PasswdMD5
	dev-perl/CSS-Minifier
	dev-perl/Date-Pcalc
	mysql? ( dev-perl/DBD-mysql )
	postgres? ( dev-perl/DBD-Pg )
	dev-perl/DBI
	gd? ( dev-perl/GD
		dev-perl/GDTextUtil
		dev-perl/GDGraph )
	dev-perl/IO-Socket-SSL
	>=dev-perl/JavaScript-Minifier-1.05
	>=dev-perl/JSON-2.21
	dev-perl/JSON-XS
	dev-perl/LWP-UserAgent-Determined
	dev-perl/Mail-POP3Client
	dev-perl/MailTools
	>=dev-perl/MIME-tools-5.427
	dev-perl/NetxAP
	dev-perl/Net-IMAP-Simple-SSL
	>dev-perl/Net-DNS-0.60
	dev-perl/Net-SMTP-SSL
	dev-perl/Net-SMTP-TLS
	dev-perl/IO-stringy
	pdf? ( >=dev-perl/PDF-API2-0.73
		virtual/perl-Compress-Raw-Zlib )
	ldap? ( dev-perl/perl-ldap )
	soap? (
		dev-perl/SOAP-Lite
		!=dev-perl/SOAP-Lite-0.711
		!=dev-perl/SOAP-Lite-0.712 )
	dev-perl/Template-Toolkit
	dev-perl/Text-CSV
	dev-perl/Text-CSV_XS
	dev-perl/TimeDate
	dev-perl/XML-Parser
	dev-perl/YAML-LibYAML
	virtual/perl-MIME-Base64
	virtual/perl-libnet
	virtual/perl-Digest-MD5
	>=virtual/perl-Digest-SHA-5.48
	virtual/mta
	apache2? ( mod_perl? ( www-servers/apache:2
		=www-apache/libapreq2-2* www-apache/mod_perl )
	!fastcgi? ( !mod_perl? ( www-servers/apache:2[suexec] ) )
	!fastcgi? ( !mod_perl? ( www-servers/apache:2[suexec] ) ) )
	fastcgi? ( dev-perl/FCGI virtual/httpd-fastcgi )
	!fastcgi? ( !apache2? ( virtual/httpd-cgi ) )"

S="${WORKDIR}/${MY_P}"
OTRS_HOME="/var/lib/otrs"

pkg_setup() {
	# The enewuser otrs will fail if apache isn't there, but it's an optional dep
	# so we create the apache user here just in case
	enewgroup apache 81
	enewuser apache 81 -1 /var/www apache
	enewuser otrs -1 -1 ${OTRS_HOME} apache
	confutils_require_any mysql postgres
}

src_prepare() {
	rm -fr "${S}/scripts"/{auto_*,redhat*,suse*,*.spec} || die
	cp Kernel/Config.pm{.dist,} || die

	sed -i -e "s:/opt/otrs:${OTRS_HOME}:g" "${S}"/Kernel/Config.pm \
		|| die "sed failed"

	grep -lR "/opt" "${S}"/scripts | \
		xargs sed -i -e "s:/opt/otrs:${OTRS_HOME}:g" \
		|| die "sed failed"

	cd Kernel/ || die
	for i in *.dist; do
		cp ${i} $(basename ${i} .dist) || die
	done

	echo "CONFIG_PROTECT=\"${OTRS_HOME}/Kernel/Config.pm \
		${OTRS_HOME}/Kernel/Config/GenericAgent.pm\"" > "${T}/50${PN}"

}

# This is too automagic, either einfo telling user or installing to /etc/cron.d/ should be preferred
pkg_config() {
	einfo "Installing cronjobs"
	crontab -u otrs /usr/share/doc/${PF}/crontab
}

src_install() {
	dodoc CHANGES.md README*

	insinto "${OTRS_HOME}"
	doins -r .fetchmailrc.dist .mailfilter.dist .procmailrc.dist RELEASE \
		Custom Kernel bin scripts var

	cat "${S}"/var/cron/*.dist > crontab
	insinto /usr/share/doc/${PF}/
	doins crontab

	for a in article log pics/images pics/stats pics sessions spool tmp tmp/CacheFileStorable; do
		keepdir "${OTRS_HOME}/var/${a}"
	done
	doenvd "${T}/50${PN}"

	systemd_dounit "${FILESDIR}/otrs-daemon.service"

}

# This is too automagic, either einfo telling user or installing to /etc/cron.d/ should be preferred
pkg_config() {
	einfo "Installing cronjobs"
	crontab -u otrs /usr/share/doc/${PF}/crontab
}

pkg_postinst() {

	einfo "Setting correct permissions ..."
		/usr/bin/env perl "${OTRS_HOME}"/bin/otrs.SetPermissions.pl "${OTRS_HOME}" \
		--otrs-user=otrs \
		--web-group=apache \
		|| die "Could not set permissions"

	einfo "Rebuilding config ..."
	sudo -u otrs /usr/bin/env perl "${OTRS_HOME}"/bin/otrs.Console.pl Maint::Config::Rebuild \
	|| die "Could not rebuild config"

	einfo "Deleting cache ..."
	sudo -u otrs /usr/bin/env perl "${OTRS_HOME}"/bin/otrs.Console.pl Maint::Cache::Delete \
	|| die "Could not delete cache"

	einfo "Installation done!"

	elog "Enable cronjobs with the following command ->"
	elog "crontab -u otrs crontab"
	elog "systemd users: enable and start OTRS daemon ->"
	elog "systemctl enable otrs-daemon"
	elog "systemctl start otrs-daemon"
}