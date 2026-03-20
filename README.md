# Docker Setup for ESP32 Zigbee Development

This setup lets you:
- Keep your source code on the host
- Build inside a reproducible Docker container
- Avoid local ESP-IDF / Python / toolchain conflicts

## Files

| File | Description |
|------|-------------|
| `Dockerfile` | Builds the development image with ESP-IDF and toolchains |
| `docker-compose.yml` | Starts the container with your repo mounted inside it |

## Prerequisites

Install:
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

If you are on **Windows with WSL2**:
- Enable Docker Desktop WSL integration for your distro (`Docker Desktop → Settings → Resources → WSL Integration`)
- Open the repo from inside WSL, not from the Windows filesystem (`/mnt/c/...`) — this avoids file permission and line-ending issues

## Recommended Repo Layout

```text
esp32-zigbee/
├── app/
│   └── temp_sensor/
│       ├── CMakeLists.txt
│       ├── partitions.csv
│       ├── sdkconfig
│       └── main/
│           ├── CMakeLists.txt
│           ├── idf_component.yml
│           ├── temp_sensor.c
│           └── temp_sensor.h
├── esp-zigbee-sdk/        ← git submodule
├── Dockerfile
├── docker-compose.yml
├── .gitignore
├── README.md
└── LICENSE
```

>Any other application should have the same layout as the temp_sensor example.

>`app/*/build/` and `app/*/managed_components/` are auto-generated — they should be in `.gitignore` and never committed.

## Cloning the Repo
 
This repo contains a submodule (`esp-zigbee-sdk`). A regular `git clone` will leave that folder **empty**. You must initialize the submodule after cloning.

```bash
git clone --recurse-submodules https://github.com/ms-itachii/esp32-Zigbee.git
```

## Start the Environment

From the repo root on your host (Docker Desktop must be running):

```bash
docker compose build          # only needed once, or after Dockerfile changes
docker compose run --rm esp-idf bash
```
> You might need to give the user permissions, to do so run `sudo usermod -aG docker $USER` and the restart WSL session.

You are now inside the container. Your repo is mounted at `/workspace/`.

Verify ESP-IDF is working:

```bash
idf.py --version
```

## Build an App

All commands below run **inside the container**.

### 1. Navigate to your app

```bash
cd /workspace/app/temp_sensor
```

### 2. Set the target chip

Always do this first on a new project. It resets `sdkconfig` for the selected chip.

```bash
idf.py set-target esp32h2     # change to esp32c6, esp32s3, etc. as needed
```

### 3. Configure the SDK

```bash
idf.py menuconfig
```

Key settings to verify:

```
Component config → Zigbee → Enable Zigbee stack       ← must be enabled
Component config → Zigbee → Zigbee device role        ← ZED/ZC/ZR (ZED for this example)
Partition Table  → Partition Table → Custom           ← point to partitions.csv
Serial flasher config → Flash size                    ← match your board
```

> After `menuconfig`, the settings are saved to `sdkconfig` in your app folder. This file should be committed to git so your config is reproducible.

### 4. Build

```bash
idf.py fullclean              # deletes the build folder 
idf.py build
```

Build output is at `app/temp_sensor/build/`.

> For subsequent builds where you only changed source or header files, you can skip `fullclean` and just run `idf.py build` for a faster build.

## Flashing

Flashing requires USB access to the device. This needs a bit of setup on WSL2.

### Step 1 — Check if the device is visible in WSL

Plug in your ESP32 board, then in a WSL terminal:

```bash
ls /dev/tty*
```

If you see `/dev/ttyACM0` or `/dev/ttyUSB0`, the device is already visible — skip to Step 3.

If not, continue to Step 2.

### Step 2 — Forward USB from Windows to WSL using usbipd

`usbipd` is a Windows tool that shares USB devices over IP into WSL.

**Install usbipd** in PowerShell (run as Administrator):

```powershell
winget install usbipd
```

**List connected USB devices** in PowerShell (a WSL terminal must be running):

```powershell
usbipd list
```

You will see output like:

```
BUSID  VID:PID    DEVICE                            STATE
2-3    303a:1001  USB Serial Device (COM4)          Not shared
```

**Bind and attach the device** (replace `2-3` with your BUSID):

```powershell
usbipd bind --busid 2-3
usbipd attach --wsl --busid 2-3
```

Now go back to WSL and run `ls /dev/tty*` again — you should see the device.

### Step 3 — Expose the device to the Docker container

Add the device to `docker-compose.yml`:

```yaml
devices:
  - /dev/ttyACM0:/dev/ttyACM0   # adjust path to match what you see in WSL
```

Then restart the container:

```bash
docker compose run --rm esp-idf bash
```

### Step 4 — Flash from inside the container

```bash
cd /workspace/app/temp_sensor
idf.py -p /dev/ttyACM0 flash
```

### Step 5 — Monitor serial output

To flash and immediately open the serial monitor for debug logs:

```bash
idf.py -p /dev/ttyACM0 flash monitor
```

Press `Ctrl+]` to exit the monitor.

## Common Issues

| Problem | Fix |
|---------|-----|
| `esp_zigbee_core.h: No such file or directory` | `CONFIG_ZB_ENABLED=y` is missing from `sdkconfig`. Copy `sdkconfig` from the working example and run `idf.py fullclean && idf.py build`. |
| `partitions.csv does not exist` | Copy `partitions.csv` from the working example, then run `idf.py fullclean && idf.py build`. |
| Config change not picked up after build | Always run `idf.py fullclean` after any change to `sdkconfig`, `CMakeLists.txt`, or project structure. |
| Device not visible in WSL | Use `usbipd attach --wsl --busid <id>` from PowerShell. See Step 2 above. |
| Permission denied on `/dev/ttyACM0` | Add `devices:` entry to `docker-compose.yml` and restart the container. |

## Useful Commands Reference

```bash
# Container
docker compose build                        # rebuild the image
docker compose run --rm esp-idf bash        # start a container session

# ESP-IDF
idf.py set-target esp32h2                   # set chip target (resets sdkconfig)
idf.py menuconfig                           # interactive configuration UI
idf.py build                                # incremental build
idf.py fullclean                            # wipe build/ folder
idf.py fullclean && idf.py build            # full clean rebuild
idf.py -p /dev/ttyACM0 flash               # flash to device
idf.py -p /dev/ttyACM0 flash monitor       # flash + open serial monitor
idf.py -p /dev/ttyACM0 monitor             # open serial monitor only
```