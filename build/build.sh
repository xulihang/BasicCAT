#!/bin/bash

cd BasicCAT/BasicCAT
export MONO_IOMAP=all
mono ../../MonoBuilder/B4JBuilder.exe -task=build
cp Objects/BasicCAT.jar ../../work/BasicCAT/
cd ../../work/
wine ../inno/ISCC.exe basiccat.iss
wine ../inno/ISCC.exe basiccat-x64.iss

