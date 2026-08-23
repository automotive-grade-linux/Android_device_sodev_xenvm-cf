# Android_device_sodev_xenvm-cf
xenvm_cuttlefish AOSP device for SoDeV usecase

This repository holds the **Raspberry Pi 4 variant** of the `xenvm-trout` AAOS guest
(DomA) used by the SoDeV disaggregated-cockpit demo. It is an *additive* device: it
modifies nothing in `device/epam/aosp-xenvm-trout`, and the upstream
`aosp_xenvm_trout_arm64` product keeps working unchanged for every other host.

## Why a separate device rather than a patch

The AAOS guest is compiled for the ISA of the **host** cores it will run on -- a virtio
guest still executes on the host's CPUs. The upstream board config resolves (through
`device/google/trout/trout_arm64/BoardConfig.mk`) to `TARGET_CPU_VARIANT := cortex-a53`,
which is right for every host this guest has been built for so far, including the
Cortex-A76 of a Raspberry Pi 5. The Cortex-A72 of a Raspberry Pi 4 is a different CPU,
and this variant is how the board says so. The reasoning, and the measurement of what
does and does not actually depend on it in AOSP 17, is in
`xenvm_trout_rpi4_arm64/BoardConfig.mk` -- read it before changing that line.

The separate `PRODUCT_DEVICE` also keeps the two boards' output trees apart
(`out/target/product/xenvm_trout_rpi4_arm64` versus `out/target/product/xenvm_trout_arm64`).
With one shared device name, switching boards in an existing checkout would silently
reuse object files built for the other CPU.

## Contents

| Path | What it is |
|---|---|
| `AndroidProducts.mk` | Declares the product and its lunch choices |
| `aosp_xenvm_trout_rpi4_arm64.mk` | The product: inherits the upstream one, overrides the identity, installs the two files below |
| `xenvm_trout_rpi4_arm64/BoardConfig.mk` | Includes the upstream board config and changes only the ISA baseline |
| `init.xenvm-buried-eth0.rc` | Starts cuttlefish's `rename_eth0`, which minradio's data call needs from Android 17 on. The whole argument, the boot timings and the measurements are in the file |
| `overlay/.../SettingsProvider/res/values/defaults.xml` | `Settings.Global` defaults for a fresh userdata: Bluetooth off, window/transition animations off |

Everything here derives from the SoDeV Raspberry Pi workspace
(`automotive-grade-linux/sodev-demo-workspace-rpi`), where it was staged into the AOSP
checkout by a build script. Moving it into a repo-managed project is what removes that
staging step for this board.

## How a build picks it up

The AOSP manifest names this repository as a project that is **not** synced by default:

```xml
<project path="device/sodev/xenvm-cf" name="automotive-grade-linux/Android_device_sodev_xenvm-cf"
         remote="github" revision="<commit>" groups="notdefault,rpi4"/>
```

`notdefault` keeps it out of every other checkout -- a Renesas V4H or a Raspberry Pi 5
build never fetches it, and nothing about their output changes. A Raspberry Pi 4 build
opts in with repo's group flag, which **replaces** the group set, so `default` has to be
named too:

```sh
repo init -u <manifest> -b <rev> -m default.xml -g default,rpi4
repo sync
lunch aosp_xenvm_trout_rpi4_arm64-trunk_staging-userdebug
```

`path` matters: AOSP finds the board config with
`find -L device -maxdepth 4 -path '*/$(TARGET_DEVICE)/BoardConfig.mk'`, and
`device/sodev/xenvm-cf/xenvm_trout_rpi4_arm64/BoardConfig.mk` sits at exactly that depth.
That same search fails with "Multiple board config files for TARGET_DEVICE" if two
configs claim one device name, which is why this variant has its own `PRODUCT_DEVICE`
rather than overriding the existing one.

## Two files that are expected to leave again

`init.xenvm-buried-eth0.rc` and the overlay are not Raspberry Pi 4 properties: they are
properties of minradio and of trout's `ro.vendor.disable_rename_eth0`, and they apply to
any `xenvm-trout` guest on Android 17. They are carried here so that a Raspberry Pi 4
build needs nothing but this repository and the upstream manifest. A copy also lives in
the workspace for the Raspberry Pi 5 build.

The fix belongs upstream in `android_device_epam_xenvm-trout`, as an opt-in gated on a
boot property. When it lands there, both copies -- this one and the workspace one --
are deleted, and this repository is left with the three board files that really are
board-specific.

## Status

The device definition, the init rc and the overlay are the ones that produced the
Raspberry Pi 4 DomA images verified on hardware on 2026-08-18 (Dom0 Zephyr / Dom0 Linux,
four-domain and DomA-only configurations). `PRODUCT_NAME`, `PRODUCT_DEVICE`, the
installed vendor paths and the file contents are unchanged by the move, so a build from
this repository produces the same guest images; what changed is where the files come
from. The manifest wiring itself (the `notdefault,rpi4` project and the group flag) is
verified by `repo init`/`repo sync` and by `lunch`, not on hardware.

## License

Apache-2.0, see `LICENSE`. Each file carries an SPDX identifier.
