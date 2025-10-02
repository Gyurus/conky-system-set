#!/bin/bash
# Module for weather location setup

# Validate a location using OpenWeatherMap Geocoding API
_validate_location() {
    local owm_key="$OWM_API_KEY"
    local loc="$1"
    if [ -z "$owm_key" ] || [ "$owm_key" = "YOUR_OPENWEATHERMAP_API_KEY" ]; then
        return 1
    fi
    local resp=$(curl -s "https://api.openweathermap.org/geo/1.0/direct?q=${loc}&limit=1&appid=${owm_key}")
    echo "$resp" | grep -q '"lat"'
}

# Suggest a valid similar location list
_get_similar_location() {
    local owm_key="$OWM_API_KEY"
    local loc="$1"
    if [ -z "$owm_key" ] || [ "$owm_key" = "YOUR_OPENWEATHERMAP_API_KEY" ]; then
        echo "Budapest,HU"
        return
    fi
    local resp=$(curl -s "https://api.openweathermap.org/geo/1.0/direct?q=${loc}&limit=5&appid=${owm_key}")
    local suggestion=$(echo "$resp" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
    local country=$(echo "$resp" | grep -o '"country":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ -n "$suggestion" ] && [ -n "$country" ]; then
        echo "${suggestion},${country}"
    else
        echo "Budapest,HU"
    fi
}

# Main function to setup weather location
get_weather_location() {
    local noninteractive="$1"
    local auto_loc="$2"
    local location=""
    # Non-interactive: use default
    if [ "$noninteractive" = true ]; then
        location="Budapest,HU"
        echo "   ℹ️  Non-interactive mode: set default location: $location"
        echo "$location"
        return
    fi
    # Auto-location: skip prompt, use ipinfo
    if [ "$auto_loc" = true ]; then
        echo "   ℹ️  Auto-location mode: detecting via IP..."
        if command -v curl >/dev/null 2>&1; then
            local info=$(curl -s ipinfo.io)
            local city=$(echo "$info" | grep '"city"' | sed 's/.*"city": "\([^\"]*\)".*/\1/')
            local country=$(echo "$info" | grep '"country"' | sed 's/.*"country": "\([^\"]*\)".*/\1/')
            if [ -n "$city" ] && [ -n "$country" ]; then
                location="${city},${country}"
                echo "   📍 Auto-detected location: $location"
            else
                location="Budapest,HU"
                echo "   ⚠️  Auto-detect failed, defaulting to: $location"
            fi
        else
            location="Budapest,HU"
            echo "   ⚠️  curl not available, defaulting to: $location"
        fi
        echo "$location"
        return
    fi
    # Interactive prompt
    read -p "   ❓ Set weather location manually? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        local attempt=1 max_attempts=3
        while [ $attempt -le $max_attempts ]; do
            read -p "   📍 Enter city or city,country: " location
            if [ -z "$location" ]; then
                location="Budapest,HU"
                break
            fi
            _validate_location "$location" && break
            echo "   ❌ Invalid location: $location"
            echo "   💡 Suggestion: $(_get_similar_location "$location")"
            attempt=$((attempt+1))
        done
    else
        # Fallback to manual default
        location="Budapest,HU"
        echo "   ℹ️  Using default location: $location"
    fi
    echo "   📍 Weather location: $location"
    echo "$location"
}
