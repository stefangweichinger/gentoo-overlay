# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: Exp $

inherit eutils

S="${WORKDIR}"
DESCRIPTION="policyd-weight is a Perl policy daemon for the Postfix MTA (2.1 and later) intended to eliminate forged envelope senders and HELOs (i.e. in bogus mails)."
HOMEPAGE="http://www.policyd-weight.org/"
SRC_URI="http://www.policyd-weight.org/releases/${PN}-${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 ppc sparc mips alpha arm hppa amd64 ia64 ppc64 s390 sh"
IUSE="doc"

DEPEND="${RDEPEND}
	>=mail-mta/postfix-2.1
	dev-perl/Net-DNS
	perl-core/Sys-Syslog"

RDEPEND=">=dev-lang/perl-5.8
	sys-apps/sed"

pkg_setup() {
	enewgroup polw
	enewuser polw -1 /bin/false /var/lib/policyd-weight polw
	pwconv || die
}

src_unpack() {
	cd "${S}" || die
	perl ./${PN} defaults >${T}/policyd-weight.conf.sample
}
src_compile() { :; }

src_install () {
	cd "${S}" || die

	# Do directory structure
	diropts -m0770 -o polw -g polw
	dodir /var/lib/policyd-weight

	# Install the files
	exeinto /usr/bin
	doexe ${PN}

	# Create configuration
	dodir /etc
	insinto /etc
	insopts -m0640 -o polw -g polw
	newins ${T}/policyd-weight.conf.sample policyd-weight.conf

	# Documentation
	dodoc changes.txt
	doman /man/man5/*.5
	doman man/man8/*.8
	if use doc; then
		dodoc documentation.txt
	fi

	# Add init script
	dodir /etc/init.d
	exeopts -m0755 -o root -g root	
	newins ${FILESDIR}/${PN}.rc ${PN}
}

pkg_postinst() {
	echo
	einfo "To make use of policyd-weight-devel, please update"
	einfo "your Postfix config."
	einfo
	einfo "Put something like this in /etc/postfix/main.cf:"
	einfo "    smtpd_recipient_restrictions ="
	einfo "           ..."
	einfo "           check_policy_service inet:127.0.0.1:12525"
	einfo
	einfo "Remember to restart Postfix after that change. Also remember"
	einfo "to make the daemon start durig boot:"
	einfo "  rc-update add ${PN} default"
	einfo
	echo
}
