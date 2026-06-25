# PipeWire for Termux (Android aarch64)

[PipeWire](https://pipewire.org) compiled for **Termux** (Android aarch64 / Bionic libc) with **AAudio** and **Oboe** backend support.

This build enables PipeWire to function as a PulseAudio-compatible server on Android devices. Audio is routed through Android's native audio stack via AAudio (NDK) and Oboe (C++), allowing audio playback and capture in Termux and within **proot-distro** environments (e.g., Ubuntu).

> **Credit:** [knyipab](https://github.com/knyipab/termux-packages/tree/10c726bbf78cd4008755f30467f7637d9763e318/packages/pipewire) originally created the `module-aaudio` and `module-oboe` patches. This repository adapts those patches for **PipeWire 1.6.7** and provides an updated build pipeline.

---

## Contents

| File | Description |
|---|---|
| `build-pipewire.sh` | Cross-compilation script using Android NDK |
| `make-deb.sh` | Debian package builder for `.deb` packaging |
| `pipewire-termux_1.6.7_aarch64.deb` | Pre-built package (see [Installation](#installation)) |
| `patches/` | Android-specific patches (AAudio, Oboe, pthread, runtime dir) |
| `android-arm64.txt` | Meson cross-compilation definition file |

---

## Installation

### 1. Install the package

```bash
dpkg -i pipewire-termux_1.6.7_aarch64.deb
```

The package installs to `/data/data/com.termux/files/usr/`. It includes:

- `pipewire`, `pipewire-pulse`, and `wireplumber` daemons
- compatibility layers
- AAudio and Oboe sink/source modules
- SPA plugins, libraries, headers, pkg-config files
- WirePlumber session manager
- Locale and config files

### 2. Copy default configuration

```bash
cp -r /data/data/com.termux/files/usr/share/pipewire /data/data/com.termux/files/home/.config/
cp -r /data/data/com.termux/files/usr/share/wireplumber /data/data/com.termux/files/home/.config/
```

### 3. First-time setup

Run the following commands to start the daemons:

```bash
pipewire &
wireplumber &
pipewire-pulse &
```

A `native` file will be created at `/data/data/com.termux/files/usr/tmp/pulse`. Once it appears, subsequent sessions only need `pipewire &` — `wireplumber` and `pipewire-pulse` will auto-launch.


Export `PULSE_SERVER` in your Termux shell:

```bash
export PULSE_SERVER="unix:/data/data/com.termux/files/usr/tmp/pulse/native"
```

Alternatively, use TCP (PipeWire also listens on `tcp:4713`):

```bash
export PULSE_SERVER="127.0.0.1"
```

### 4. Start the daemon

```bash
pipewire &
```

Check that it is running:

```bash
pactl info
```

Expected output (your version may differ):

```
Server String: unix:/data/data/com.termux/files/usr/tmp/pulse/native
Library Protocol Version: 35
Server Protocol Version: 35
Is Local: yes
Client Index: 83
Tile Size: 65472
User Name: u0_a3702
Host Name: localhost
Server Name: PulseAudio (on PipeWire 1.6.7)
Server Version: 15.0.0
Default Sample Specification: float32le 2ch 48000Hz
Default Channel Map: front-left,front-right                                                  Default Sink: oboe-sink-6770-27
Default Source: oboe-source-6770-28
Cookie: 71dd:408d
```

---

## Usage with proot-distro Ubuntu (login with `--shared-tmp`)

In **proot-distro** Ubuntu, install the relevant PipeWire and WirePlumber packages, then:

```bash
export PULSE_SERVER="unix:/tmp/pulse/native"
```

Then verify the connection:

```bash
pactl info
```

```
Server String: unix:/tmp/pulse/native
Library Protocol Version: 35
Server Protocol Version: 35
Is Local: yes
Client Index: 82
Tile Size: 65472
User Name: u0_a3702
Host Name: localhost
Server Name: PulseAudio (on PipeWire 1.6.7)
Server Version: 15.0.0
Default Sample Specification: float32le 2ch 48000Hz
Default Channel Map: front-left,front-right
Default Sink: oboe-sink-6770-27
Default Source: oboe-source-6770-28
Cookie: 71dd:408d
```


The output should match what you see in Termux. Audio applications inside the proot can now play and record through PipeWire, which routes audio through Android's AAudio/Oboe stack.

There is no need to start PipeWire with `systemctl` inside proot-distro Ubuntu — as long as the same `PULSE_SERVER` is used.

---

## Building from source in termux environment


### Prerequisites

Current PipeWire version: 1.6.7

1. Clone this repo (extracted from the [PipeWire 1.6.7 source](https://github.com/PipeWire/pipewire/archive/refs/tags/1.6.7.zip)):

```bash
git clone https://github.com/leefm0204/pipewire-termux-proot.git
```

2. cd pipewire-termux-proot
```bash
cd pipewire-termux-proot
```

3. Download subproject

```bash
meson subprojects download
```

4. Adjust the Android NDK environment flags based on your setup, then run:

```bash
./build-pipewire.sh
```

The script:
1. Copies AAudio/Oboe module sources from `patches/` into the source tree
2. Applies Android-specific patches (pthread compatibility, runtime directory, ALSA log API, Oboe/AAudio module registration)
3. Configures with `meson setup` using the `android-arm64.txt` cross-file (minimal features, SPA plugins enabled, WirePlumber session manager)
4. Compiles and installs to `$PREFIX`


---

## Modules provided

| Module | Description |
|---|---|
| `libpipewire-module-aaudio-sink` | AAudio-based audio playback sink |
| `libpipewire-module-aaudio-source` | AAudio-based audio capture source |
| `libpipewire-module-oboe-sink` | Oboe-based audio playback sink (C++) |
| `libpipewire-module-oboe-source` | Oboe-based audio capture source (C++) |
| `module-aaudio-sink` / `module-aaudio-source` (Pulse) | PulseAudio native protocol modules for AAudio |
| `module-oboe-sink` / `module-oboe-source` (Pulse) | PulseAudio native protocol modules for Oboe |

These are loaded in `pipewire.conf` and `pipewire-pulse.conf` — see `patches/0004.patch` for the configuration.

## License

PipeWire is licensed under the [MIT license](LICENSE). See [COPYING](COPYING) for details. Exceptions are noted in [LICENSE](LICENSE).

