#!/bin/sh

cat > src/include/openssl/umbrella.h <<EOF
#include "ssl.h"
#include "crypto.h"
#include "aes.h"
/* The following macros are defined by base.h. The latter is the first file included by the
   other headers. */
#if defined(OPENSSL_ARM) || defined(OPENSSL_AARCH64)
#  include "arm_arch.h"
#endif
#include "asn1.h"
#include "asn1_mac.h"
#include "asn1t.h"
#include "blowfish.h"
#include "cast.h"
#include "chacha.h"
#include "cmac.h"
#include "conf.h"
#include "cpu.h"
#include "curve25519.h"
#include "des.h"
#include "dtls1.h"
#include "hkdf.h"
#include "md4.h"
#include "md5.h"
#include "obj_mac.h"
#include "objects.h"
#include "opensslv.h"
#include "ossl_typ.h"
#include "pkcs12.h"
#include "pkcs7.h"
#include "pkcs8.h"
#include "poly1305.h"
#include "rand.h"
#include "rc4.h"
#include "ripemd.h"
#include "safestack.h"
#include "srtp.h"
#include "x509.h"
#include "x509v3.h"
EOF
cat > src/include/openssl/BoringSSL.modulemap <<EOF
framework module openssl {
  umbrella header "umbrella.h"
  textual header "arm_arch.h"
  export *
  module * { export * }
}
EOF
# The symbol prefixing mechanism is performed by redefining BoringSSL symbols with "#define
# SOME_BORINGSSL_SYMBOL GRPC_SHADOW_SOME_BORINGSSL_SYMBOL". Unfortunately, some symbols are
# already redefined as macros in BoringSSL headers in the form "#define SOME_BORINGSSL_SYMBOL
# SOME_BORINGSSL_SYMBOL" Such type of redefinition will cause "SOME_BORINGSSL_SYMBOL redefined"
# error when using together with our prefix header. So the workaround in the below lines removes
# all such type of #define directives.
sed -i'.back' '/^#define \\([A-Za-z0-9_]*\\) \\1/d' src/include/openssl/*.h
# Remove lines of the format below for the same reason above
#     #define SOME_BORINGSSL_SYMBOL \
#         SOME_BORINGSSL_SYMBOL
sed -i'.back' '/^#define.*\\\\$/{N;/^#define \\([A-Za-z0-9_]*\\) *\\\\\\n *\\1/d;}' src/include/openssl/*.h
# We are renaming openssl to openssl_grpc so that there is no conflict with openssl if it exists
/usr/bin/find . -type f \( -path '*.h' -or -path '*.cc' -or -path '*.c' \) -print0 | xargs -0 -L1 sed -E -i'.grpc_back' 's;#include <openssl/;#include <openssl_grpc/;g'