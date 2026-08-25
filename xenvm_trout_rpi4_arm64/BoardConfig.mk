# SPDX-License-Identifier: Apache-2.0
#
# Board configuration for the Raspberry Pi 4 variant of the xenvm-trout AAOS guest.
#
# The upstream board config is included wholesale and only the ISA baseline is changed
# after it, so this file stays a delta rather than a fork: partition sizes, bootconfig,
# sepolicy dirs, kernel cmdline and the mesa3d/virgl selection all keep coming from
# device/epam/aosp-xenvm-trout.
include device/epam/aosp-xenvm-trout/xenvm_trout_arm64/BoardConfig.mk

# --- Raspberry Pi 4 (BCM2711) ISA baseline ---------------------------------------
# The included config resolves, via device/google/trout/trout_arm64/BoardConfig.mk, to
#     TARGET_CPU_VARIANT := cortex-a53
# and LLVM's cortex-a53 feature set implies the ARMv8 crypto extensions. That holds for
# the CPU Arm specifies, and for every host this guest has been built for so far --
# including the Cortex-A76 of a Raspberry Pi 5.
#
# The Cortex-A72 of a Raspberry Pi 4 does NOT implement them:
#     # cat /proc/cpuinfo
#     Features : fp asimd evtstrm crc32 cpuid
# BoringSSL folds its capability check at compile time when the compiler says the
# extensions are present, so /init reaches sha256su0 and dies with SIGILL before
# first-stage mount. The guest never boots, and nothing in the build warns.
#
# Naming cortex-a72 is how this board says it is not the CPU the upstream config assumes.
#
# It is NOT, however, what stops the folding -- that claim was in this comment and it is
# wrong. Measured on AOSP 17: build/soong/cc/config/arm64_device.go maps "cortex-a72" to
# ${config.Arm64CortexA53Cflags}, i.e. plain -mcpu=cortex-a53, and `nocrypto` appears
# nowhere in soong or in the generated ninja. (Do not confuse it with the Yocto side, where
# meta-raspberrypi really does set DEFAULTTUNE = "cortexa72-nocrypto" for raspberrypi4-64 --
# that tune exists and is in effect for the DomD host services. There is no AOSP equivalent.)
#
# What actually keeps the guest off the extensions on 17 is BoringSSL: clang-r596125 defines
# none of __ARM_FEATURE_{AES,SHA2,CRYPTO} for -mcpu=cortex-a53/a72/a76, so
# external/boringssl/src/crypto/internal.h takes its OPENSSL_STATIC_ARMCAP-undefined path
# and dispatches through OPENSSL_armcap_P at run time. That is board-independent.
#
# This variant is kept anyway, for two reasons that do not depend on the above:
#   - it gives the board its own PRODUCT_DEVICE, so the two boards' out/target/product trees
#     stay apart and objects built for the other CPU cannot be reused silently;
#   - whether the CPU variant matters for some other library has not been established.
#     Only libcrypto's SHA256 path was examined. Removing it is a decision for hardware
#     verification, not for a build-time reading of the toolchain.
# TARGET_ARCH_VARIANT stays armv8-a; it is the CPU variant that names the extensions.
#
# This is the AAOS-guest counterpart of the Yocto side, where the DomD host services are
# built with meta-raspberrypi's own DEFAULTTUNE = "cortexa72-nocrypto" for
# raspberrypi4-64 and are therefore already safe.
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_VARIANT := cortex-a72
