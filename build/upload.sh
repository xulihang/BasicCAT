#!/bin/bash
export GITHUB_TOKEN=<my token>
./linux-amd64-github-release upload \
    --user xulihang \
    --repo BasicCAT \
    --tag v1.10.3 \
    --name "BasicCAT-crossplatforms.zip" \
    --file BasicCAT-crossplatforms.zip
./linux-amd64-github-release upload \
    --user xulihang \
    --repo BasicCAT \
    --tag v1.10.3 \
    --name "BasicCAT_mac.dmg" \
    --file BasicCAT_mac.dmg
./linux-amd64-github-release upload \
    --user xulihang \
    --repo BasicCAT \
    --tag v1.10.3 \
    --name "BasicCAT-windows-x64.exe" \
    --file ./exe/BasicCAT-windows-x64.exe
./linux-amd64-github-release upload \
    --user xulihang \
    --repo BasicCAT \
    --tag v1.10.3 \
    --name "BasicCAT-windows-x86.exe" \
    --file ./exe/BasicCAT-windows-x86.exe	