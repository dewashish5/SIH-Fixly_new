#!/bin/bash
IP=$(hostname -I | awk '{print $1}')
echo "Detected local IP: $IP"
sed -i "s|http://[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*:8005|http://$IP:8005|g" frontend/lib/core/network/api_config.dart
echo "Updated API URL in frontend/lib/core/network/api_config.dart to http://$IP:8005"
