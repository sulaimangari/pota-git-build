#!/usr/bin/bash

SMEE_URL=$(curl https://smee.io/new | grep -o "https://smee.io/[A-Za-z0-9-]*")
gh secret set SMEE_URL --body "$SMEE_URL"

PUB_KEY=$(cat ~/.ssh/id_*.pub)
gh secret set PUB_KEY --body "$PUB_KEY"

mkdir -p .github/workflows

touch .github/workflows/build.yaml

cat <<'EOF' >> .github/workflows/build.yaml
name: build

on: workflow_dispatch

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Install Dependency
      run: |
        sudo apt update
        sudo apt install jo net-tools
        URL="https://api.github.com/repos/ekzhang/bore/releases/latest"
        curl -s $URL | awk -F\" '/browser_download_url.*x86_64-unknown-linux-musl.tar.gz/{system("curl -OL " $(NF-1))}'
        tar -xvf *.tar.gz
        sudo cp bore /usr/bin/bore
        exec bash

    - name: Transfer Secret
      env: 
        SMEE_URL : ${{ secrets.AUTHORIZED_KEY }}
        PUB_KEY : ${{ secrets.PUB_KEY }}
      run: |
        mkdir ~/.ssh
        chmod 700 ~/.ssh
        echo $PUB_KEY >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys

    - name: Create Tunnel
      run: |
        nohup bore local 22 --to bore.pub &
        BORE_PORT=$(cat nohup.out | grep -oP 'bore.pub:\s*\K\d+')
        while true; do
            jo bore=$BORE_PORT | curl -X POST -H "Content-Type: application/json" -d @- $SMEE_URL

            if netstat | grep ssh | head -n 1 ; then 
              break
            else 
              sleep 1
            fi
        done
EOF

curl https://smee.io/ShpRVaKYRBLWStXS -H "accept: application/json" 
