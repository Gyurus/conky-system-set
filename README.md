# Conky Network Monitor

A dynamic and visually clean Conky setup for monitoring your system’s network activity in real time. Includes auto-configuration for your active network interface, stylish output, and startup automation.

https://i.postimg.cc/Bb3J2GF1/Screenshot-2025-06-13-20-01-14.png

---

## ✨ Features

- Transparent panel-style layout with a modern font (`Roboto Mono`)
- Live upload/download speeds with graphs
- Total data sent/received
- Auto-detection of active network interface
- Lightweight and desktop-integrated
- Startup script included

---

## 📁 Files Overview

### `conky.template.conf`

> Template file for Conky with a placeholder (`@@IFACE@@`) that gets replaced by your actual network interface name.

**Includes:**
- Upload/Download speed and graphs
- Total sent/received data
- Uses `Roboto Mono` font
- Styled with semi-transparent background

---

### `conkyset.sh`

> Auto-generates a `conky.conf` file by detecting your active network interface and replacing the `@@IFACE@@` placeholder.

**Usage:**
```bash
./conkyset.sh
