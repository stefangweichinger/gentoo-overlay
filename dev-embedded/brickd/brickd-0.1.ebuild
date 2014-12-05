# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/ganeti/ganeti-2.6.1.ebuild,v 1.4 2013/09/12 22:29:37 mgorny Exp $

EAPI="4"

inherit eutils confutils bash-completion-r1 git-2

MY_PV="${PV/_rc/~rc}"
MY_P="${PN}-${MY_PV}"

	EGIT_REPO_URI="https://github.com/Tinkerforge/brickd"
	KEYWORDS="~amd64 ~x86"

DESCRIPTION="tinkerforge brickd"
HOMEPAGE="https://github.com/Tinkerforge/brickd"

LICENSE="GPL-2"
SLOT="0"
IUSE=""

#S="${WORKDIR}/${MY_P}"

DEPEND=" virtual/libusb
	virtual/udev
	${GIT_DEPEND}"
RDEPEND="${DEPEND}"

src_compile() {
cd "${S}"/src/brickd
emake DESTDIR="${D}" 
}

src_install () {
cd "${S}"/src/brickd
		insinto /usr/bin
		doins brickd
		fperms 0755 /usr/bin/brickd
	#emake DESTDIR="${D}" install || die "emake install failed"
}
