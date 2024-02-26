#!/bin/bash
useradd -s /bin/bash -m $1
echo $1:$2 |chpasswd
if [[ $# -eq 3 && $3 == yes ]];
then
        usermod -aG sudo $1
fi
