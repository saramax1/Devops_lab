
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
        sudo apk add --no-cache "${packagesNeeded[@]}" -y
    elif [ -x "$(command -v apt-get)" ];
    then
        sudo apt-get install "${packagesNeeded[@]}" -y
    elif [ -x "$(command -v dnf)" ];
    then
        sudo dnf install "${packagesNeeded[@]}" -y
    elif [ -x "$(command -v zypper)" ];
    then
        sudo zypper install "${packagesNeeded[@]}" -y
    else
        echo "FAILED TO INSTALL PACKAGE: Package manager not found. You must manually install: "${packagesNeeded[@]}"">&2;
    fi
}

#install requir package for vagrant
PACKAGES="curl python3-pip virtualbox ansible vagrant snapd"

package_installer $PACKAGES
snap install lxd
echo -e "enter the nodes Number:\n"
#read NODES_NUMBER
NODES_NUMBER=3
for N in $(seq "$NODES_NUMBER");
do
        echo $N
        lxc-create --name lcontainer_$N  --template download -- --dist ubuntu --release jammy --arch amd64
        lxc-start --name lcontainer_$N
        lxc-info --name lcontainer_$N
        lxc-info --name lcontainer_$N |grep IP: |cut -d":" -f 2 | tr -d " " |xargs echo container_$N >> .hosts

done
