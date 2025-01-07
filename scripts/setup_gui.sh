#!/bin/bash

# Advanced Setup Script for GUI (XFCE4, VNC, NoVNC)
set -e

LOG_FILE="/tmp/gui_setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting GUI (XFCE4, VNC, NoVNC) setup..."

# Update and install required packages
echo "Updating package list and installing tools..."
sudo apt update -y
sudo apt install -y \
    xfce4 xfce4-goodies novnc python3-websockify python3-numpy tightvncserver \
    nano screen htop curl wget openssl

# Configure VNC
echo "Configuring VNC server..."
pkill Xtightvnc || true
rm -rf $HOME/.vnc

vncserver || true
vncserver -kill :1 || true

cat <<EOL > "$HOME/.vnc/xstartup"
#!/bin/bash
xrdb \$HOME/.Xresources
startxfce4 &
EOL
chmod +x "$HOME/.vnc/xstartup"

vncserver :1

# Configure NoVNC
SSL_CERT_PATH="$HOME/novnc.pem"
echo "Generating SSL certificates for NoVNC..."
openssl req -x509 -nodes -newkey rsa:3072 -keyout "$SSL_CERT_PATH" -out "$SSL_CERT_PATH" -days 3650 -subj "/CN=novnc.local"

echo "Starting NoVNC..."
websockify -D --web=/usr/share/novnc/ --cert="$SSL_CERT_PATH" 6080 localhost:5901

# Create systemd services for VNC and NoVNC
echo "Configuring persistent services..."

# VNC systemd service
sudo bash -c 'cat <<EOF > /etc/systemd/system/vncserver.service
[Unit]
Description=Start VNC Server
After=syslog.target network.target

[Service]
Type=forking
User='$(whoami)'
ExecStart=/usr/bin/vncserver :1
ExecStop=/usr/bin/vncserver -kill :1
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

# NoVNC systemd service
sudo bash -c 'cat <<EOF > /etc/systemd/system/novnc.service
[Unit]
Description=Start NoVNC
After=syslog.target network.target

[Service]
ExecStart=/usr/bin/websockify --web=/usr/share/novnc/ --cert='$SSL_CERT_PATH' 6080 localhost:5901
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl enable vncserver novnc
sudo systemctl start vncserver novnc

# Display connection details
IP_ADDRESS=$(curl -s ifconfig.me)
echo "Setup complete!"
echo "Access NoVNC at: https://$IP_ADDRESS:6080"
echo "VNC Password: Nakkucoder"
