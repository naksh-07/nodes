#!/bin/bash

# Advanced script for setting up XFCE4, VNC server, and NoVNC on GitHub Codespaces
set -e

LOG_FILE="/tmp/vnc_setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting XFCE4 + VNC + NoVNC setup script with cleanup..."

# Step 1: Stop and remove existing VNC server instances
echo "Stopping any running VNC server processes..."
pkill Xtightvnc || true

echo "Removing existing VNC server files..."
rm -rf $HOME/.vnc

# Step 2: Remove previously installed packages if present
echo "Removing existing packages..."
sudo apt remove -y xfce4 xfce4-goodies novnc python3-websockify python3-numpy tightvncserver || true
sudo apt autoremove -y || true

# Step 3: Reinstall necessary packages
echo "Updating package list and installing dependencies..."
sudo apt update -y
sudo apt install -y xfce4 xfce4-goodies novnc python3-websockify python3-numpy tightvncserver htop nano neofetch openssl

# Step 4: Create SSL certificates for NoVNC
SSL_CERT_PATH="$HOME/novnc.pem"
echo "Generating SSL certificates for NoVNC at $SSL_CERT_PATH..."
openssl req -x509 -nodes -newkey rsa:3072 -keyout "$SSL_CERT_PATH" -out "$SSL_CERT_PATH" -days 3650 -subj "/CN=novnc.local"

# Step 5: Start and configure VNC server
echo "Setting up VNC server..."
USER=$(whoami)
vncserver || true  # Start once to generate default configuration files
vncserver -kill :1 || true  # Stop the server to configure it

# Backup existing xstartup if it exists
if [ -f "$HOME/.vnc/xstartup" ]; then
  echo "Backing up existing xstartup file..."
  mv "$HOME/.vnc/xstartup" "$HOME/.vnc/xstartup.bak"
fi

# Create a new xstartup file
echo "Creating new xstartup file..."
cat <<EOL > "$HOME/.vnc/xstartup"
#!/bin/bash
xrdb \$HOME/.Xresources
startxfce4 &
EOL

# Ensure xstartup is executable
chmod +x "$HOME/.vnc/xstartup"

# Step 6: Restart VNC server with the proper configuration
echo "Restarting VNC server..."
vncserver :1

# Step 7: Start NoVNC
echo "Starting NoVNC..."
websockify -D --web=/usr/share/novnc/ --cert="$SSL_CERT_PATH" 6080 localhost:5901

# Step 8: Display connection information
IP_ADDRESS=$(curl -s ifconfig.me)
echo "Setup complete!"
echo "Access your NoVNC session using the following URL:"
echo "https://$IP_ADDRESS:6080"

# Troubleshooting note
echo "If you encounter issues, check the log file at $LOG_FILE."
