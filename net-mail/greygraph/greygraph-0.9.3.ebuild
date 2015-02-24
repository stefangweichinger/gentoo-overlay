# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-mail/greygraph/greygraph-1.14-r2.ebuild,v 1.5 2011/12/29 21:37:27 halcy0n Exp $

EAPI=4
inherit eutils

DESCRIPTION="A greylisting statistics RRDtool frontend for Postfix"
HOMEPAGE="http://www.std-soft.com"
SRC_URI="http://www.std-soft.com/images/greygraph_r0.9.3.tar.gz"

LICENSE="GPL-2"
# Change SLOT to 0 when appropriate
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND="dev-lang/perl
	dev-perl/File-Tail
	>=net-analyzer/rrdtool-1.2.2[perl]"
DEPEND=">=sys-apps/sed-4"

pkg_setup() {
	# add user and group for greygraph daemon
	# also add ggraph to the group adm so it's able to
	# read syslog logfile /var/log/messages (should be owned by
	# root:adm with permission 0640)
	enewgroup ggraph
	enewuser ggraph -1 -1 /var/empty ggraph,adm
}

src_prepare() {
	sed -i \
		-e "s|\(my \$rrd = '\).*'|\1/var/lib/greygraph/greygraph.rrd'|" \
		-e "s|\(my \$rrd_virus = '\).*'|\1/var/lib/greygraph/greygraph_virus.rrd'|" \
		greygraph.cgi || die "sed greygraph.cgi failed"
}

src_install() {
	# for the RRDs
	dodir /var/lib
	diropts -oggraph -gggraph -m0750
	dodir /var/lib/greygraph
	keepdir /var/lib/greygraph

	# log and pid file
	diropts ""
	dodir /var/log
	dodir /var/run
	diropts -oggraph -gadm -m0750
	dodir /var/log/greygraph
	keepdir /var/log/greygraph

	# logrotate config for greygraph log
	diropts ""
	dodir /etc/logrotate.d
	insopts -m0644
	insinto /etc/logrotate.d
	newins "${FILESDIR}"/greygraph.logrotate-new greygraph

	# greygraph daemon
	newbin greygraph.pl greygraph

	# greygraph CGI script
	exeinto /usr/share/${PN}
	doexe greygraph.cgi
	insinto  /usr/share/${PN}
	doins greygraph.css

	# init/conf files for greygraph daemon
	newinitd "${FILESDIR}"/greygraph.initd-new greygraph
	newconfd "${FILESDIR}"/greygraph.confd-new greygraph

	# docs
	dodoc README CHANGES
}

pkg_postinst() {
	# Fix ownerships - previous versions installed these with
	# root as owner
	if [[ ${REPLACING_VERSIONS} < 1.13 ]] ; then
		if [[ -d /var/lib/greygraph ]] ; then
			chown ggraph:ggraph /var/lib/greygraph
		fi
		if [[ -d /var/log/greygraph ]] ; then
			chown ggraph:adm /var/log/greygraph
		fi
		if [[ -d /var/run/greygraph ]] ; then
			chown ggraph:adm /var/run/greygraph
		fi
	fi
	elog "Mailgraph will run as user ggraph with group adm by default."
	elog "This can be changed in /etc/conf.d/greygraph if it doesn't fit."
	elog "Remember to adjust MG_DAEMON_LOG, MG_DAEMON_PID and MG_DAEMON_RRD"
	elog "as well!"
	ewarn "Please make sure the MG_LOGFILE (default: /var/log/messages) is readable"
	ewarn "by group adm or change MG_DAEMON_GID in /etc/conf.d/greygraph accordingly!"
	ewarn
	ewarn "Please make sure *all* mail related logs (MTA, spamfilter, virus scanner)"
	ewarn "go to the file /var/log/messages or change MG_LOGFILE in"
	ewarn "/etc/conf.d/greygraph accordingly! Otherwise greygraph won't get to know"
	ewarn "the corresponding events (virus/spam mail found etc.)."
	elog
	elog "Checking for user apache:"
	if egetent passwd apache >&/dev/null; then
		elog "Adding user apache to group ggraph so the included"
		elog "CGI script is able to read the greygraph RRD files"
		if ! gpasswd -a apache ggraph >&/dev/null; then
			eerror "Failed to add user apache to group ggraph!"
			eerror "Please check manually."
		fi
	else
		elog
		elog "User apache not found, maybe we will be running a"
		elog "webserver with a different UID?"
		elog "If that's the case, please add that user to the"
		elog "group ggraph manually to enable the included"
		elog "CGI script to read the greygraph RRD files:"
		elog
		elog "\tgpasswd -a <user> ggraph"
	fi
	ewarn
	ewarn "greygraph.cgi is installed in /usr/share/${PN}/"
	ewarn "You need to put it somewhere accessible though a web-server."
}
