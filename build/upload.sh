#!/bin/bash
export GITHUB_TOKEN=9bf32471b55b41ae1570f5a8b5b907a3f9fb9d96
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