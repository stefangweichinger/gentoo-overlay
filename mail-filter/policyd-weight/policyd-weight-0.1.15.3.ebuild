# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: Exp $

EAPI=2
inherit eutils versionator

MY_PV="$(replace_version_separator 3 'dev')"
DESCRIPTION="policyd-weight is a Perl policy daemon for the Postfix MTA (2.1 and later) intended to eliminate forged envelope senders and HELOs (i.e. in bogus mails)."
HOMEPAGE="http://www.policyd-weight.org/"
SRC_URI="mirror://sourceforge/${PN}/${PN}-${MY_PV}-1.src.rpm"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 ppc sparc mips alpha arm hppa amd64 ia64 ppc64 s390 sh"
IUSE="doc geoip p0f s25r"
S="${WORKDIR}/${PN}-${MY_PV}"
DEPEND="${RDEPEND}
	>=mail-mta/postfix-2.1
	dev-perl/Net-DNS
	perl-core/Sys-Syslog
	p0f?	( net-analyzer/p0f )
	geoip?	( >=dev-perl/Geo-IP-1.34 )"
RDEPEND="app-arch/rpm2targz
	>=dev-lang/perl-5.8
	sys-apps/sed"

pkg_setup() {
	enewgroup polw
	enewuser polw -1 -1 "/var/lib/policyd-weight" polw
	pwconv || die

	# Inform user about development release
	echo
	ewarn "This is a development release of ${PN}. If you don't want to install a"
	ewarn "development release, then abort emerge by hitting Ctrl+C now."
	echo
	ewarn "Waiting 5 seconds before continuing ..."
	echo
	epause 5
}

src_prepare() {
	cd "${S}/usr/sbin/"
	epatch "${FILESDIR}"/${PF}.assignment.patch
	use p0f		&& epatch "${FILESDIR}"/${PF}.p0f.patch
	use geoip	&& epatch "${FILESDIR}"/${PF}.extendedGeoIP.patch
	use s25r	&& epatch "${FILESDIR}"/${PF}.s25r.patch
	epatch "${FILESDIR}"/${PF}.result-url.patch
}

src_unpack() {
	mkdir -p "${WORKDIR}"
	cd "${WORKDIR}"
	rpm2targz "${DISTDIR}/${A}" || die "Failed to convert rpm to tar.gz"
	tar zxpf *.tar.gz -C "${WORKDIR}" >/dev/null 2>&1 || die "Unpacking source archive failed"
	tar zxpf ${PN}-${MY_PV}.tar.gz -C "${WORKDIR}" >/dev/null 2>&1 || die "Unpacking archive failed"
	rm -f *.tar.gz *.spec >/dev/null 2>&1
}

src_install () {
	cd "${S}"

	# Do directory structure
	diropts -m0770 -o polw -g polw
	dodir /var/lib/policyd-weight
	dodir /var/lib/policyd-weight/cores
	dodir /var/lib/policyd-weight/cores/cache

	# Install the perl file
	dosbin usr/sbin/${PN}

	# Create configuration
	perl "${S}"/usr/sbin/${PN} defaults | sed "s:'/tmp/\.policyd\-weight/':'/var/lib/policyd-weight/':g" >"${T}"/policyd-weight.conf
	dodir /etc
	insinto /etc
	insopts -m0640 -o polw -g polw
	doins "${T}"/policyd-weight.conf

	# Documentation
	doman usr/share/man/man[1-9]/*
	use doc		&& dodoc changes.txt documentation.txt todo.txt policyd-weight.conf.sample

	# Add init script
	newinitd ${FILESDIR}/${PN}.initd-r1 ${PN}
}

pkg_postinst() {
	echo
	einfo "To make use of ${PN}, please update your Postfix config."
	einfo
	einfo "Put something like this in /etc/postfix/main.cf:"
	einfo "    smtpd_recipient_restrictions ="
	einfo "        ..."
	einfo "        check_policy_service inet:127.0.0.1:12525"
	einfo
	einfo "Remember to restart Postfix after that change. Also remember to make"
	einfo "the daemon start durig boot:"
	einfo "    rc-update add ${PN} default"
	einfo
	echo
}
