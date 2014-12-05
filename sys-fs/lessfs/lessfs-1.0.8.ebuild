# Copyright 1999-2010 Gentoo Foundation 
# Distributed under the terms of the GNU General Public License v2 
# $Header: $ 

DESCRIPTION="lessfs - Dedup through FUSE" 
HOMEPAGE="http://www.lessfs.com" 
SRC_URI="http://downloads.sourceforge.net/project/${PN}/${PN}/${P}/${P}.tar.gz" 

LICENSE="GPL-3" 
SLOT="0" 
KEYWORDS="~amd64 ~x86" 
IUSE="lzo crypt" 

DEPEND=">=dev-db/tokyocabinet-1.4.42 
        >=sys-fs/fuse-2.8.0 
        crypt? ( dev-libs/openssl ) 
        lzo? ( dev-libs/lzo )" 

RDEPEND="" 

src_compile() { 
    use crypt && myconf="--with-crypto" 
    use lzo && myconf="${myconf} --with-lzo" 
    econf ${myconf} || die "econf failed" 
    emake || die "emake failed" 
} 

src_install () { 
    make DESTDIR="${D}" install || die "make install failed" 
    dodoc ChangeLog INSTALL NEWS README 
    insinto /etc 
    doins ./etc/lessfs.cfg 
}
