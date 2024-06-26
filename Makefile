# $NetBSD: Makefile,v 1.16 2024/04/15 20:25:07 schmonz Exp $
#

PKGNAME=		rc.d-boot-20240415
CATEGORIES=		pkgtools

MAINTAINER=		schmonz@NetBSD.org
COMMENT=		Run package rc.d scripts at boot on any supported OS
LICENSE=		2-clause-bsd

ONLY_FOR_PLATFORM=	# empty by default
RCDBOOT_STYLE=		unknown

.include "../../mk/bsd.prefs.mk"

.if exists(/sbin/rcorder)
RCORDER=		/sbin/rcorder
.else
DEPENDS+=		rc.subr>=20181226:../../pkgtools/rc.subr
DEPENDS+=		rcorder-[0-9]*:../../pkgtools/rcorder
RCORDER=		${PREFIX}/sbin/rcorder
.endif

NO_CHECKSUM=		yes
BUILD_TARGET=		rc.d-boot-pause
MAKE_FILE=		/dev/null
USE_TOOLS+=		true:run

SUBST_CLASSES=		paths
SUBST_STAGE.paths=	pre-configure
SUBST_FILES.paths=	rc.d-boot rc.d-boot-fg
SUBST_FILES.paths+=	org.pkgsrc.rc.d-boot.plist \
			pkgsrc-rc.d-boot \
			pkgsrc-rc.d-boot.service
SUBST_VARS.paths=	GREP SYSCONFBASE PKGNAME PREFIX RCD_SCRIPTS_DIR RCORDER TRUE VARBASE

FILES_SUBST+=		RCDBOOT_STYLE=${RCDBOOT_STYLE:Q}
FILES_SUBST+=		RCD_SCRIPTS_DIR=${RCD_SCRIPTS_DIR:Q}
FILES_SUBST+=		UNPRIVILEGED=${UNPRIVILEGED:Q}
FILES_SUBST+=		EGDIR=${PREFIX:Q}/${EGDIR:Q}

EGDIR=			share/examples/${PKGBASE}

SLASH_TO_MOLLIFY_PKGLINT=	/

.if ${OPSYS} == "Darwin" && exists(/Library/LaunchDaemons)
RCDBOOT_STYLE=		darwin-launchd
.  if ${UNPRIVILEGED:U:tl} == "no"
CONF_FILES+=		${PREFIX}/${EGDIR}/org.pkgsrc.rc.d-boot.plist \
			${SLASH_TO_MOLLIFY_PKGLINT}Library/LaunchDaemons/org.pkgsrc.rc.d-boot.plist
.  endif
.elif ${OPSYS} == "FreeBSD" && exists(/etc/rc.d)
RCDBOOT_STYLE=		freebsd-native
.elif ${OPSYS} == "Linux" && exists(/run/systemd/system) && exists(/bin/systemctl)
RCDBOOT_STYLE=		linux-systemd
CONF_FILES+=		${PREFIX}/${EGDIR}/pkgsrc-rc.d-boot.service \
			${SLASH_TO_MOLLIFY_PKGLINT}etc/systemd/system/pkgsrc-rc.d-boot.service
.elif ${OPSYS} == "Linux" && exists(/etc/rc.d/init.d) && exists(/sbin/chkconfig)
RCDBOOT_STYLE=		linux-sysv-redhat
CONF_FILES_PERMS+=	${PREFIX}/${EGDIR}/pkgsrc-rc.d-boot \
			/etc/init.d/pkgsrc-rc.d-boot \
			${REAL_ROOT_USER} ${REAL_ROOT_GROUP} ${RCD_SCRIPTS_MODE}
.elif ${OPSYS} == "Linux" && exists(/etc/init.d) && exists(/usr/sbin/update-rc.d)
RCDBOOT_STYLE=		linux-sysv-debian
CONF_FILES_PERMS+=	${PREFIX}/${EGDIR}/pkgsrc-rc.d-boot \
			/etc/init.d/pkgsrc-rc.d-boot \
			${REAL_ROOT_USER} ${REAL_ROOT_GROUP} ${RCD_SCRIPTS_MODE}
.elif ${OPSYS} == "NetBSD" && exists(/etc/rc.d)
RCDBOOT_STYLE=		netbsd-native
.elif ${OPSYS} == "OpenBSD" && exists(/etc/rc.d/rc.subr)
RCDBOOT_STYLE=		openbsd-rcd
.endif

.if ${RCDBOOT_STYLE} == "unknown"
# Help wanted! Some known boot schemes we'd like to support:
# - https://wiki.alpinelinux.org/wiki/Alpine_Linux_Init_System
# - https://wiki.gentoo.org/wiki/Project:OpenRC
# - http://smarden.org/runit/
# - https://jdebp.eu/Softwares/nosh/
# - http://upstart.ubuntu.com
BROKEN_ON_PLATFORM+=	${OPSYS}-*-*
.endif

BUILD_DEFS+=		RCDBOOT_STYLE RCD_SCRIPTS_DIR VARBASE
INSTALLATION_DIRS=	sbin ${EGDIR}

do-extract:
	${CP} -R ${FILESDIR} ${WRKSRC}

do-install:
.for i in org.pkgsrc.rc.d-boot.plist \
	pkgsrc-rc.d-boot.service
	${INSTALL_DATA} ${WRKSRC}/${i} ${DESTDIR}${PREFIX}/${EGDIR}/
.endfor
.for i in pkgsrc-rc.d-boot
	${INSTALL_SCRIPT} ${WRKSRC}/${i} ${DESTDIR}${PREFIX}/${EGDIR}/
.endfor
.for i in rc.d-boot rc.d-boot-fg rc.d-boot-pause
	${INSTALL_SCRIPT} ${WRKSRC}/${i} ${DESTDIR}${PREFIX}/sbin/
.endfor

.include "../../mk/bsd.pkg.mk"
