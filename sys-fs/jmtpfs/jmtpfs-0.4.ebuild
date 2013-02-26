# Copyright 1999-2012 Gentoo Foundation 
# Distributed under the terms of the GNU General Public License v2 
# $Header: $ 

EAPI=4 

inherit eutils 

DESCRIPTION="a FUSE based MTP filesystem designed to make exchanging files between Android devices and Linux" 
HOMEPAGE="http://research.jacquette.com/jmtpfs-exchanging-files-between-android-devices-and-linux/" 
SRC_URI="http://research.jacquette.com/wp-content/uploads/2012/05/${P}.tar.gz" 

LICENSE="GPL" 
SLOT="0" 
KEYWORDS="~x86 ~amd64" 
IUSE="" 

DEPEND="media-libs/libmtp 
        sys-fs/fuse" 
RDEPEND="${DEPEND}" 

src_unpack() { 

     unpack ${A} 
     cd "${S}"/src

     epatch "${FILESDIR}"/${PN}-gcc-4.7.patch 
}
