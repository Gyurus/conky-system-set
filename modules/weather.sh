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

# Auto-detect location via IP and return a safe default on failure.
detect_weather_location() {
    local fallback="Budapest,HU"
    if ! command -v curl >/dev/null 2>&1; then
        echo "$fallback"
        return
    fi
    local info city country
    info=$(curl -s ipinfo.io 2>/dev/null)
    city=$(echo "$info" | grep '"city"' | sed 's/.*"city": "\([^"]*\)".*/\1/')
    country=$(echo "$info" | grep '"country"' | sed 's/.*"country": "\([^"]*\)".*/\1/')
    if [ -n "$city" ] && [ -n "$country" ]; then
        echo "${city},${country}"
    else
        echo "$fallback"
    fi
}

# Check that wttr.in responds with usable data for the location.
check_weather_location() {
    local location="$1"
    if [ -z "$location" ]; then
        return 1
    fi
    if ! command -v curl >/dev/null 2>&1; then
        return 1
    fi
    local resp
    resp=$(curl -s --max-time 5 "https://wttr.in/${location}?format=%t" 2>/dev/null)
    if [ -z "$resp" ]; then
        return 1
    fi
    echo "$resp" | grep -qi "unknown location\|not found\|error" && return 1
    return 0
}

# Persist the chosen location for startup updates.
save_weather_location() {
    local location="$1"
    if [ -z "$location" ]; then
        return 1
    fi
    mkdir -p "$HOME/.config/conky"
    echo "$location" > "$HOME/.config/conky/.conky_location"
}

# Update the weather location in the active config file.
update_weather_location_in_config() {
    local config_file="$1"
    local new_location="$2"
    if [ -z "$config_file" ] || [ -z "$new_location" ] || [ ! -f "$config_file" ]; then
        return 1
    fi
    local escaped_location
    # Escape for sed substitution
    escaped_location=$(printf '%s\n' "$new_location" | sed -e 's/[&\\|]/\\&/g')
    
    # URL-encode the location for wttr.in API calls
    # Replace spaces with + and encode special characters
    local url_encoded_location
    url_encoded_location=$(printf '%s' "$new_location" | jq -sRr @uri | sed 's/%20/+/g')
    if [ -z "$url_encoded_location" ]; then
        # Fallback if jq is not available: simple sed-based encoding
        url_encoded_location=$(printf '%s' "$new_location" | sed 's/ /+/g; s/,/%2C/g; s/á/a/g; s/é/e/g; s/í/i/g; s/ó/o/g; s/ú/u/g')
    fi
    
    sed -i \
        -e "s|Weather: [^\$]*|Weather: ${escaped_location}|g" \
        -e "s|wttr.in/[^?[:space:]\"]*|wttr.in/${url_encoded_location}|g" \
        "$config_file"
}
