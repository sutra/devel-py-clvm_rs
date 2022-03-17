PORTNAME=	clvm_rs
PORTVERSION=	0.1.19
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

CARGO_CRATES=	bls12_381-0.5.0 \
		hex-0.4.3 \
		lazy_static-1.4.0 \
		num-bigint-0.4.0 \
		pyo3-0.14.2 \
		openssl-0.10.35 \
		ff-0.10.0 \
		group-0.10.0 \
		pairing-0.20.0 \
		rand_core-0.6.2 \
		subtle-2.4.0 \
		num-integer-0.1.44 \
		num-traits-0.2.14 \
		autocfg-1.0.1 \
		cfg-if-0.1.10 \
		cfg-if-1.0.0 \
		ctor-0.1.20 \
		indoc-0.3.6 \
		inventory-0.1.10 \
		libc-0.2.95 \
		parking_lot-0.11.1 \
		paste-0.1.18 \
		pyo3-macros-0.14.2 \
		unindent-0.1.7 \
		bitflags-1.2.1 \
		openssl-sys-0.9.64 \
		openssl-src-111.15.0+1.1.1k \
		foreign-types-0.3.2 \
		once_cell-1.7.2 \
		block-buffer-0.9.0 \
		digest-0.9.0 \
		fake-simd-0.1.2 \
		opaque-debug-0.3.0 \
		bitvec-0.22.0 \
		byteorder-1.4.3 \
		quote-1.0.9 \
		syn-1.0.72 \
		indoc-impl-0.3.6 \
		proc-macro-hack-0.5.19 \
		ghost-0.1.2 \
		inventory-impl-0.1.10 \
		instant-0.1.9 \
		lock_api-0.4.4 \
		parking_lot_core-0.8.3 \
		paste-impl-0.1.18 \
		pyo3-macros-backend-0.14.2 \
		pyo3-build-config-0.14.2 \
		cc-1.0.68 \
		pkg-config-0.3.19 \
		vcpkg-0.2.13 \
		foreign-types-shared-0.1.0 \
		block-padding-0.1.0 \
		byte-tools-0.3.1 \
		generic-array-0.14.0 \
		funty-1.2.0 \
		radium-0.6.2 \
		tap-1.0.1 \
		wyz-0.4.0 \
		proc-macro2-1.0.27 \
		unicode-xid-0.2.2 \
		scopeguard-1.1.0 \
		smallvec-1.6.1 \
		redox_syscall-0.2.8 \
		typenum-1.13.0 \
		winapi-i686-pc-windows-gnu-0.4.0 \
		winapi-x86_64-pc-windows-gnu-0.4.0 \
		winapi-0.3.9 \
		sha2-0.9.5 \
		cpufeatures-0.1.1 \
		wasm-bindgen-0.2.75 \
		wasm-bindgen-macro-support-0.2.75 \
		wasm-bindgen-backend-0.2.75 \
		wasm-bindgen-macro-0.2.75 \
		wasm-bindgen-shared-0.2.75 \
		wasm-bindgen-test-0.3.25 \
		wasm-bindgen-test-macro-0.3.25 \
		wasm-bindgen-futures-0.4.25 \
		bumpalo-3.7.0 \
		log-0.4.14 \
		console_error_panic_hook-0.1.6 \
		web-sys-0.3.52 \
		js-sys-0.3.52 \
		scoped-tls-1.0.0

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
	${STRIP_CMD} ${WRKSRC}/target/release/lib${PORTNAME}.so
	${INSTALL_DATA} ${WRKSRC}/target/release/lib${PORTNAME}.so ${STAGEDIR}${PREFIX}/lib
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
