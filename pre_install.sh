#!/bin/bash

echo -e "Gathering Facts About Your OS\n"
echo -e "************************************************\n"
echo -e "OS Name And Version:\n"
cat /etc/os-release

echo -e "************************************************\n"


package_manager(){
    declare -A osInfo;
    osInfo[/etc/redhat-release]=yum
    osInfo[/etc/arch-release]=pacman
    osInfo[/etc/gentoo-release]=emerge
    osInfo[/etc/SuSE-release]=zypp
    osInfo[/etc/debian_version]=apt-get
    osInfo[/etc/alpine-release]=apk

    for f in ${!osInfo[@]}
    do
        if [[ -f $f ]];then
            echo "OS Default Packge Manger:" ${osInfo[$f]}
        fi
    done
}
package_manager

package_installer(){
    packagesNeeded=($@)
    if [ -x "$(command -v apk)" ];
    then
        sudo apk add --no-cache "${packagesNeeded[@]}"
    elif [ -x "$(command -v apt-get)" ];
    then
        sudo apt-get install "${packagesNeeded[@]}"
    elif [ -x "$(command -v dnf)" ];
    then
        sudo dnf install "${packagesNeeded[@]}"
    elif [ -x "$(command -v zypper)" ];
    then
        sudo zypper install "${packagesNeeded[@]}"
    else
        echo "FAILED TO INSTALL PACKAGE: Package manager not found. You must manually install: "${packagesNeeded[@]}"">&2;
    fi
}

#install requir package for vagrant 
PACKAGES="curl python3-pip virtualbox vagrant ansible"
package_installer $PACKAGES
echo -e "enter the nodes Number:\n"
read NODES_NUMBER

sed -i -e "s/NODES_NUMBER/${NODES_NUMBER}/g" ./Vagrantfile

mkdir data{1..$NODES_NUMBER}

vagrant up 


