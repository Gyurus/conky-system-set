#!/bin/bash

# Detect active interface: prefer Ethernet, fallback to Wi-Fi
iface=$(ip route get 1.1.1.1 2>/dev/null | awk '/dev/ {print $5; exit}')
[ -z "$iface" ] && iface=$(nmcli device status | awk '$3 == "connected" && $2 == "wifi" {print $1; exit}')
[ -z "$iface" ] && iface="enp7s0"  # final fallback (adjust as needed)

# Save the interface
mkdir -p "$HOME/.config/conky"
echo "$iface" > "$HOME/.config/conky/.conky_iface"

# Replace @@IFACE@@ in template
sed "s/@@IFACE@@/$iface/g" "$HOME/.config/conky/conky.template.conf" > "$HOME/.config/conky/conky.conf"

# Remove last line (if ]] exists)
sed -i '$d' "$HOME/.config/conky/conky.conf"

# Append final blocks
cat >> "$HOME/.config/conky/conky.conf" <<'EOF'
${color1}Wi-Fi Info${color};${if_existing /proc/net/wireless};SSID: ${exec iw dev | awk '/ssid/ {print $2; exit}'};Signal: ${exec awk 'NR==3 {print int(($3 / 70) * 100)}' /proc/net/wireless}%;${endif}
${color1}Monthly Data Usage (from 1st)${color}
${execpi 300 bash -c '
iface=$(cat $HOME/.config/conky/.conky_iface)
baseline_file="$HOME/.config/conky/.vnstat_baseline"
today=$(date +%d)
if [ ! -f "$baseline_file" ] || [ "$today" = "01" ]; then
  vnstat -i "$iface" --oneline | cut -d\; -f11,12 > "$baseline_file"
fi
read rx0 tx0 < <(cut -d\; -f1,2 "$baseline_file")
read rx1 tx1 < <(vnstat -i "$iface" --oneline | cut -d\; -f11,12)
rx_used=$((rx1 - rx0))
tx_used=$((tx1 - tx0))
used=$((rx_used + tx_used))
echo "Used this month: ${used} MB"
'}
Host: $alignr$nodename
Uptime: $alignr$uptime
Kernel: $alignr$kernel
${color1}Temperatures${color}
CPU (avg): ${execi 10 sensors | awk '/Package id 0:/ {print $4; exit}'}
${cpugraph 20,320 ff6600 ffff00}
GPU Temp: ${alignr}${execi 30 bash -c '
  if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader
  else
    sensors | awk "/edge/ {print \$2; exit}"
  fi'}
${color1}CPU/RAM${color}
CPU: ${cpu}% ${cpubar 6}
RAM: $mem / $memmax ($memperc%) ${membar 6}
Swap: $swap / $swapmax ($swapperc%) ${swapbar 6}
${hr 1}
${color1}Storage${color}
Root: ${fs_used /} / ${fs_size /} ${alignr}(${fs_used_perc /}%) ${fs_bar 6 /}
Home: ${fs_used /home} / ${fs_size /home} ${alignr}(${fs_used_perc /home}%) ${fs_bar 6 /home}
${color1}Disk I/O (nvme0n1)${color}
Read: ${diskio_read /dev/nvme0n1} ${alignr}Write: ${diskio_write /dev/nvme0n1}
${diskiograph_read /dev/nvme0n1 20,150 ffcc66 663300} ${alignr}${diskiograph_write /dev/nvme0n1 20,150 66ff66 003300}
${hr 1}
${color1}Top CPU${color}
${top name 1} ${alignr}${top cpu 1}%
${top name 2} ${alignr}${top cpu 2}%
${top name 3} ${alignr}${top cpu 3}%
${color1}Top RAM${color}
${top_mem name 1} ${alignr}${top_mem mem 1}%
${top_mem name 2} ${alignr}${top_mem mem 2}%
${top_mem name 3} ${alignr}${top_mem mem 3}%
${hr 1}
${if_existing /sys/class/power_supply/BAT0}
${color1}Battery${color}
${battery_short BAT0} - ${battery_time BAT0} ${battery_bar 6 BAT0}
${endif}
${color1}Weather${color};${execpi 1800 curl -s 'wttr.in/?format=4'}
${color1}Public IP${color};${execpi 300 curl -s https://ipinfo.io/ip}
${alignc}${font Roboto Mono:bold:size=10}${color2}${time %A, %d %B %Y}
${alignc}${font Roboto Mono:size=16}${color1}${time %H:%M:%S}${font}
]];
EOF
# Launch Conky with final config
conky -c "$HOME/.config/conky/conky.conf"
