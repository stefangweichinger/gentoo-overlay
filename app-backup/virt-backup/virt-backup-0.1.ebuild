# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-accessibility/speakup/speakup-9999.ebuild,v 1.3 2009/12/03 20:43:20 williamh Exp $

DESCRIPTION="A perl script for managing libvirt KVM-guests for backups"
HOMEPAGE="http://repo.firewall-services.com/misc/virt"

SRC_URI="http://repo.firewall-services.com/misc/virt/${PN}.pl"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"

DEPEND="dev-perl/Sys-Virt
dev-perl/XML-Simple
perl-core/Getopt-Long"

RDEPEND="${DEPEND}"

S="${WORKDIR}"

src_unpack() {
	# Nothing to unpack
	:
}

src_install() {
	cd "${S}/.."
	newbin "./distdir/${PN}.pl" "${PN}" || die "newbin failed"
}
