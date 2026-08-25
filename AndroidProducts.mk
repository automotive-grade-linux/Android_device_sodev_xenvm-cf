# SPDX-License-Identifier: Apache-2.0
#
# A Raspberry Pi 4 variant of the xenvm-trout AAOS guest.
#
# This is an ADDITIVE device: nothing in device/epam/aosp-xenvm-trout is modified, and
# the upstream aosp_xenvm_trout_arm64 product keeps working unchanged for every other
# host. The variant exists because the AAOS guest is compiled for the ISA of the HOST
# cores it will run on -- a virtio guest still executes on the host's CPUs -- and the
# upstream board config resolves to a cortex-a53 CPU variant, which is not the
# Cortex-A72 of a BCM2711. See xenvm_trout_rpi4_arm64/BoardConfig.mk for what was
# actually measured on AOSP 17 (the CPU variant turns out NOT to decide whether the
# guest uses the ARMv8 crypto extensions) and for the two reasons the variant is kept
# regardless.
#
# A separate PRODUCT_DEVICE (rather than an override of the existing one) also keeps the
# two boards' AOSP output trees apart: out/target/product/xenvm_trout_rpi4_arm64 versus
# out/target/product/xenvm_trout_arm64. With one shared device name, switching boards in
# an existing checkout would silently reuse object files built for the other CPU.

PRODUCT_MAKEFILES := \
	aosp_xenvm_trout_rpi4_arm64:$(LOCAL_DIR)/aosp_xenvm_trout_rpi4_arm64.mk \

COMMON_LUNCH_CHOICES := \
	aosp_xenvm_trout_rpi4_arm64-trunk_staging-eng \
	aosp_xenvm_trout_rpi4_arm64-trunk_staging-userdebug \
