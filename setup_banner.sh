#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root." >&2
    exit 1
fi

# From now on there is no need to prefix your commands with "sudo"

BANNER_DIR=/etc/update-motd.d/
BANNER_FILE=95-custom-banner
BANNER="${BANNER_DIR}${BANNER_FILE}"

# Install figlet if necessary
if ! command -v figlet >/dev/null 2>&1; then
    echo "figlet is not installed. Installing it..."
    apt update
    apt install -y figlet

    if ! command -v figlet >/dev/null 2>&1; then
        echo "Failed to install figlet." >&2
        exit 1
    fi
fi

# Ask user for banner text
read -r -p "Enter banner text: " NAME

if [ -z "$NAME" ]; then
    echo "Banner text cannot be empty." >&2
    exit 1
fi

# Ask user for color
echo
echo "Available colors:"
echo "  BLACK"
echo "  RED"
echo "  GREEN"
echo "  YELLOW"
echo "  BLUE"
echo "  MAGENTA"
echo "  CYAN"
echo "  WHITE"
echo

read -r -p "Choose banner color [GREEN]: " COLOR
COLOR=${COLOR:-GREEN}
COLOR=$(printf '%s' "$COLOR" | tr '[:lower:]' '[:upper:]')

# Convert color name to ANSI code
case "$COLOR" in
    BLACK)   COLOR_CODE='30' ;;
    RED)     COLOR_CODE='31' ;;
    GREEN)   COLOR_CODE='32' ;;
    YELLOW)  COLOR_CODE='33' ;;
    BLUE)    COLOR_CODE='34' ;;
    MAGENTA) COLOR_CODE='35' ;;
    CYAN)    COLOR_CODE='36' ;;
    WHITE)   COLOR_CODE='37' ;;
    *)
        echo "Invalid color: $COLOR" >&2
        echo "Please choose one of: BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE" >&2
        exit 1
        ;;
esac

# Create ASCII Art
ASCII_ART=$(figlet -f smslant "$NAME")

# Create file
touch "$BANNER"

# Write script header
cat > "$BANNER" <<EOF
#!/bin/bash

printf '\\033[${COLOR_CODE}m'
EOF

# Write one printf per row of ASCII art
while IFS= read -r line; do
    # Escape backslashes and single quotes for the generated script
    line=${line//\\/\\\\}
    line=${line//\'/\'\\\'\'}

    printf "printf '%s\\\\n'\n" "$line" >> "$BANNER"
done <<< "$ASCII_ART"

# Reset color and add empty line
cat >> "$BANNER" <<'EOF'
printf '\033[0m'
printf '\n'
EOF

# Make it executable
chmod +x "$BANNER"

# Ask user if they want to test it
read -r -p "Do you want to test it now? [y/N]: " TEST

if [[ "$TEST" =~ ^[Yy]$ ]]; then
    run-parts "$BANNER_DIR"
fi

echo -e '\033[0;32mDONE!\033[0m'
exit 0