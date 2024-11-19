#!/bin/bash

# Update the system and install necessary packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y wireguard nginx git python3 python3-pip curl

# Install WireGuard
sudo apt install -y wireguard

# Generate private and public keys for WireGuard
PRIVATE_KEY=$(wg genkey)
PUBLIC_KEY=$(echo $PRIVATE_KEY | wg pubkey)

# Save the private and public keys to files
echo $PRIVATE_KEY > /etc/wireguard/privatekey
echo $PUBLIC_KEY > /etc/wireguard/publickey

# Display the generated keys
echo "Private Key: $PRIVATE_KEY"
echo "Public Key: $PUBLIC_KEY"

# Create WireGuard config file
cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $PRIVATE_KEY
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <VPN_PEER_PUBLIC_KEY>  # Replace this with your peer's public key
Endpoint = 45.33.27.236:51820      # Your server's IP and WireGuard port
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

# Enable and start the WireGuard service
sudo systemctl enable wg-quick@wg0
sudo wg-quick up wg0

# Verify if WireGuard is running
sudo wg

# Clone your GitHub repository for the web app
cd /var/www/
git clone https://github.com/oavla/ulrua-vpn.git my-search-app
cd my-search-app

# Install Python dependencies (requirements.txt should be in your repo)
sudo pip3 install -r requirements.txt

# Create the Flask app as a systemd service for persistence
sudo tee /etc/systemd/system/my-search-app.service <<EOF
[Unit]
Description=Gunicorn instance to serve Flask app
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/my-search-app
ExecStart=/usr/bin/python3 /var/www/my-search-app/app.py

[Install]
WantedBy=multi-user.target
EOF

# Start and enable the Flask app service
sudo systemctl daemon-reload
sudo systemctl start my-search-app
sudo systemctl enable my-search-app

# Set up Nginx to serve the Flask app
sudo tee /etc/nginx/sites-available/my-search-app <<EOF
server {
    listen 80;
    server_name 45.33.27.236;  # Replace with your domain name if available

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# Enable the Nginx site and restart Nginx
sudo ln -s /etc/nginx/sites-available/my-search-app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Allow necessary ports through firewall
sudo ufw allow 51820/udp
sudo ufw allow 80/tcp
sudo ufw enable

# Final message
echo "VPN and Web App setup complete. Your web app should be available at http://45.33.27.236"
