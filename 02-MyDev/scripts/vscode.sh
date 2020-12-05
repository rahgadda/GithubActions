#!/bin/bash

if [[ -z "$NGROK_TOKEN" ]]; then
  echo "Please set 'NGROK_TOKEN'"
  exit 2
fi

if [[ -z "$USER_PASS" ]]; then
  echo "Please set 'USER_PASS' for user: $USER"
  exit 3
fi

echo "### Install ngrok ###"
wget -q https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-386.zip
unzip ngrok-stable-linux-386.zip
chmod +x ./ngrok

echo "### Update user: $USER password ###"
echo -e "$USER_PASS\n$USER_PASS" | sudo passwd "$USER"

echo "### Install VSCode ###"
git clone https://github.com/microsoft/vscode
cd vscode
yarn install 
yarn run compile
yarn run web

echo "### Waiting for 8080 port to start  ###"
while ! nc -z localhost 8080 </dev/null; do sleep 10; done

echo "### Start ngrok proxy for 8080 port ###"
rm -f .ngrok.log
./ngrok authtoken "$NGROK_TOKEN"
./ngrok http 8080 --log ".ngrok.log" &

sleep 10
HAS_ERRORS=$(grep "command failed" < .ngrok.log)

if [[ -z "$HAS_ERRORS" ]]; then
  echo ""
  echo "=========================================="
  echo "To connect: $(grep -o -E "http://(.+)" < .ngrok.log | sed "s/http:\/\//ssh $USER@/" | sed "s/:/ -p /")"
  echo "=========================================="
else
  echo "$HAS_ERRORS"
  exit 4
fi