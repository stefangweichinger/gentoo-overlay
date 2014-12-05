# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-misc/jdictionary/jdictionary-1.8-r2.ebuild,v 1.6 2007/12/09 13:54:27 nelchael Exp $

inherit java-pkg-2 eutils

DESCRIPTION="max! controlling software"
HOMEPAGE="http://www.maxbuddy.de"
SRC_URI="http://download.maxbuddy.de/MAXBuddy-r${PV}-linux.tgz"

IUSE=""
SLOT="0"
LICENSE="LGPL-2.1"
KEYWORDS="amd64 ppc x86"

RDEPEND=">=virtual/jre-1.3"
DEPEND=">=virtual/jdk-1.3
		app-arch/unzip"
S="${WORKDIR}"

src_unpack() {
	unpack ${A}
	cd "${S}"
	mkdir compiled

	jar xf launcher.jar || die "failed to unpack jar"
	#cp -r resources compiled
}

#src_compile() {
#	ejavac -classpath . $(find . -name \*.java) -d compiled || die "failed to build"
#	jar cf ${PN}.jar -C compiled . || die "failed to make jar"
#}

src_install() {
	java-pkg_dojar ${PN}.jar

	java-pkg_dolauncher ${PN} --main org.fenwulf.maxbuddy
	make_desktop_entry ${PN} maxbuddy
}
