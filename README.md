# Conky Network Monitor

A dynamic and visually clean Conky setup for monitoring your system’s network activity in real time. Includes auto-configuration for your active network interface, stylish output, and startup automation.

![Screenshot](https://your-image-link-if-any) <!-- Optional: Add a screenshot -->

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
./conkyset.sh
This creates conky.conf, ready for use. - 

conkystartup.sh
Creates the final congif for conky andlaunches Conky with the generated config.

Usage:

./conkystartup.sh

It will:

Kill existing Conky instances (optional, depending on how it's written).

Set up the configuration.

Launch Conky.

🚀 Installation
Make the scripts executable:

chmod +x conkyset.sh conkystartup.sh

Run the startup script:

./conkystartup.sh

🖼️ Requirements
Conky v1.10 or newer

Roboto Mono font (sudo apt install fonts-roboto-fontface)

Compositor (e.g., picom) for true transparency

bash

📌 Notes
Designed for Linux desktops (tested on Linux Mint)

Customize conky.template.conf for additional stats (CPU, RAM, weather, etc.)

Works for both wired and wireless interfaces

🧑‍💻 License
MIT License — free for personal and commercial use. Attribution appreciated but not required.




