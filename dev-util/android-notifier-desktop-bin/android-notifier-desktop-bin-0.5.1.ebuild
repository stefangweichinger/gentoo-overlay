# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"
inherit eutils

MY_PN="${PN/-bin}" 

DESCRIPTION="Desktop event notifier for Android devices"
HOMEPAGE="http://code.google.com/p/android-notifier/"
SRC_URI="amd64?  ( http://android-notifier.googlecode.com/files/${MY_PN}-${PV}-linux-amd64.zip )
         x86? ( http://android-notifier.googlecode.com/files/${MY_PN}-${PV}-linux-i386.zip )"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="libnotify bluetooth"

RDEPEND=">=virtual/jre-1.6
	bluetooth? ( net-wireless/bluez )
	libnotify? ( x11-libs/libnotify )"
DEPEND="${RDEPEND}"

src_install() {
	insinto /usr/share/"${MY_PN}" || die
	doins -r "${WORKDIR}"/"${MY_PN}"/* || die

	make_wrapper android-notifier-desktop ./run.sh /usr/share/"${MY_PN}" || die

	doicon ${MY_PN}/icons/${MY_PN}.png || die 

	make_desktop_entry android-notifier "AndroidNotifier" \
	/usr/share/pixmaps/${MY_PN}-desktop.png "Utility" || die
	fperms 755 /usr/share/"${MY_PN}"/run.sh
}
