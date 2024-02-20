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
