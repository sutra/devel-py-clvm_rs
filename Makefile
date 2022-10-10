PORTNAME=	clvm_rs
PORTVERSION=	0.1.23
CATEGORIES=	devel python
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}

MAINTAINER=	risner@stdio.com
COMMENT=	Chia's Rust clvm_rs library

LICENSE=	APACHE20 BSD3CLAUSE MIT UNLICENSE
LICENSE_COMB=	multi

BUILD_DEPENDS=	${PYTHON_PKGNAMEPREFIX}maturin>=0.8.3:devel/py-maturin@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}pip>=20.2.3:devel/py-pip@${PY_FLAVOR}

# TODO notes are included in this file.
USES+=		cargo python:3.7+ ssl
USE_GITHUB=	yes
GH_ACCOUNT=	Chia-Network

USE_PYTHON=	autoplist concurrent distutils

CARGO_CRATES=	autocfg-1.1.0 \
		bitflags-1.3.2 \
		bitvec-1.0.0 \
		block-buffer-0.10.2 \
		bls12_381-0.7.0 \
		byteorder-1.4.3 \
		cc-1.0.73 \
		cfg-if-1.0.0 \
		cpufeatures-0.2.2 \
		crypto-common-0.1.4 \
		digest-0.10.3 \
		ff-0.12.0 \
		foreign-types-0.3.2 \
		foreign-types-shared-0.1.1 \
		funty-2.0.0 \
		generic-array-0.14.5 \
		group-0.12.0 \
		hex-0.4.3 \
		lazy_static-1.4.0 \
		libc-0.2.126 \
		num-bigint-0.4.3 \
		num-integer-0.1.45 \
		num-traits-0.2.15 \
		once_cell-1.13.0 \
		openssl-0.10.40 \
		openssl-macros-0.1.0 \
		openssl-src-111.22.0+1.1.1q \
		openssl-sys-0.9.74 \
		pairing-0.22.0 \
		pkg-config-0.3.25 \
		proc-macro2-1.0.40 \
		quote-1.0.20 \
		radium-0.7.0 \
		rand_core-0.6.3 \
		sha2-0.10.2 \
		subtle-2.4.1 \
		syn-1.0.98 \
		tap-1.0.1 \
		typenum-1.15.0 \
		unicode-ident-1.0.1 \
		vcpkg-0.2.15 \
		version_check-0.9.4 \
		wyz-0.5.0

CARGO_BUILD=	no
CARGO_INSTALL=	no

# TODO - Should I patch the library to remove winapi requirements?

# This is to prevent Mk/Uses/python.mk do-configure target from firing.
do-configure:

# TODO Has Cargo.toml and pyproject.toml, but no setup.py. Requires maturin.
do-build:
	@(cd ${BUILD_WRKSRC} ; \
		${ECHO_MSG} "===>  Builing Maturin Pyo3 bindings"; \
		${SETENV} ${MAKE_ENV} maturin build --release \
			${WITH_DEBUG:D:U--strip})

# Stage the .so library.
do-install:
	${STRIP_CMD} ${WRKSRC}/target/release/libclvmr.so
	${INSTALL_DATA} ${WRKSRC}/target/release/libclvmr.so ${STAGEDIR}${PREFIX}/lib
# TODO Portlint concerned about possible direct use of install, but we need
#	to extract the whl into staging. Requires pip.
	${SETENV} ${MAKE_ENV} pip install --isolated --root=${STAGEDIR} \
		--ignore-installed --no-deps ${WRKSRC}/target/wheels/*.whl

# Create the cached byte-code files.
post-install:
	(cd ${STAGEDIR}${PREFIX} && \
	${PYTHON_CMD} ${PYTHON_LIBDIR}/compileall.py -d ${PREFIX} \
	-f ${PYTHONPREFIX_SITELIBDIR:S;${PREFIX}/;;})
#	${STRIP_CMD} ${STAGEDIR}${PYTHONPREFIX_SITELIBDIR}/clvm*.so
# Regenerate .PLIST.pymodtemp from ${STAGEDIR} since the framework
# does not yet support Cargo.toml+pyproject.toml installs.
	@${FIND} ${STAGEDIR} \
		-type f -o -type l | \
		${SORT} | \
		${SED} -e 's|${STAGEDIR}||' \
		> ${WRKDIR}/.PLIST.pymodtmp

do-test:
	@(cd ${WRKSRC}/tests && ${SETENV} ${TEST_ENV} \
		${PYTHON_CMD} generate-programs.py; \
		${PYTHON_CMD} run-programs.py)

# TODO I'm not sure if these messages are errors or noops:
# ===> Creating unique files: Move MAN files needing SUFFIX
# ===> Creating unique files: Move files needing SUFFIX

.include <bsd.port.mk>
