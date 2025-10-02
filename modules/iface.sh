#!/bin/bash
# Module to detect active network interface

get_iface() {
    local iface
    iface=$(ip -o -4 addr show up | awk '!/ lo / {print $2; exit}')
    if [ -z "$iface" ]; then
        iface=$(ip route | awk '/default/ {print $5; exit}')
    fi
    if [ -z "$iface" ]; then
        iface=$(ip link show | awk -F': ' '/^[0-9]+:/ && !/lo:/ {print $2; exit}')
    fi
    if [ -z "$iface" ]; then
        iface="eth0"
    fi
    echo "$iface"
}
