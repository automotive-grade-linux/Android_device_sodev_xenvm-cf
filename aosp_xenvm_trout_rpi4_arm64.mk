# SPDX-License-Identifier: Apache-2.0
#
# Raspberry Pi 4 variant of aosp_xenvm_trout_arm64.
#
# Everything about the guest is inherited from the upstream product; only the identity
# is different, so that this variant gets its own PRODUCT_DEVICE (and therefore its own
# BoardConfig.mk and its own out/target/product/ tree). The board-specific part is in
# xenvm_trout_rpi4_arm64/BoardConfig.mk.
#
# The inherit has to come first: the upstream makefile ends with its own PRODUCT_NAME /
# PRODUCT_DEVICE / PRODUCT_MODEL assignments, so ours have to be written after it to win.
$(call inherit-product, device/epam/aosp-xenvm-trout/aosp_xenvm_trout_arm64.mk)

PRODUCT_NAME := aosp_xenvm_trout_rpi4_arm64
PRODUCT_DEVICE := xenvm_trout_rpi4_arm64
PRODUCT_MODEL := xenvm arm64 trout (Raspberry Pi 4)

# Start the interface rename that minradio's data call depends on. cuttlefish already
# ships the service and a trigger for it, but trout sets ro.vendor.disable_rename_eth0
# so that trigger never fires; overriding that is deliberate and argued in the .rc.
# Without this, AAOS never finishes a data call and retries setupDataCall at 7-13 Hz --
# measured at 186 % of a physical core for 1 h 42 m with nothing on screen. The whole
# argument, the measurements and the boot timings that decide the trigger are in the .rc
# itself; read that before touching this line. Same shape as trout's own virtwifi.rc
# entry in device/google/trout/aosp_trout_arm64.mk.
PRODUCT_COPY_FILES += \
    device/sodev/xenvm-cf/init.xenvm-buried-eth0.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.xenvm-buried-eth0.rc

# Settings.Global defaults for a fresh userdata: Bluetooth off (no transport in this
# guest, and com.android.bluetooth crash-loops without one) and window/transition
# animations off (the device model, not the GPU, pays for them). The overlay file
# carries the measurements and the runtime equivalents for an existing /data.
DEVICE_PACKAGE_OVERLAYS += device/sodev/xenvm-cf/overlay
