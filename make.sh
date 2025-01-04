#!/bin/bash

nasm solarvga.asm -l solarvga.lst -o solarvga.com
cp solarvga.com solarvga.sys
