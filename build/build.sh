#!/bin/bash

cd ~/BasicCAT/work/
wine ../inno/ISCC.exe basiccat.iss
wine ../inno/ISCC.exe basiccat-x64.iss
zip -q -r BasicCAT-crossplatforms.zip crossplatform

