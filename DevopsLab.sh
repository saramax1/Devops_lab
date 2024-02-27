
#!/bin/bash
#get_os_info: Gathering Facts about HOST
get_os_info(){
    echo -e "Gathering Facts About Your OS\n"
    echo -e "************************************************\n"
    echo -e "OS Name And Version:\n"
    cat /etc/os-release
    echo -e "************************************************"
}

#package_manager: Find OS package_manager
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

#package_installer: Install Packges Base on your Default Packge Manger
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

make_inventory_for_ansible(){
        echo "plase Select Monitor Server"
        monitor_server=""
        select d in $(cat .hosts|sed 's/^[ \t]*//'| tr -s " " | tr " " ":" |cut -d ":" -f1,2)
        do
                echo "you Select: $d as monitor"
                monitor_server=$d
                break
        done
        echo -e "[monitorserver]\n$(echo $monitor_server|cut -d':' -f2) \n[nodeservers]" > prometheus_inventory

        while IFS= read -r line
        do
                if [ $(echo $monitor_server|cut -d ":" -f2) != $( echo "$line" |sed 's/^[ \t]*//'| tr -s " " | tr " " ":" |cut -d ":" -f2) ]
                then
                        echo "$line" |sed 's/^[ \t]*//'| tr -s " " | tr " " ":" |cut -d ":" -f2 >> prometheus_inventory
                fi
        done < .hosts

        echo "Your Inventory:"
        cat prometheus_inventory
        echo "****************"

        ansible-inventory -i prometheus_inventory --graph
}

run_lxc(){
    lxc-create --name $1  --template download -- --dist $2 --release $3 --arch $4
    lxc-start --name $1
    lxc-info --name $1
    lxc-info --name $1 |grep IP: |cut -d":" -f 2 | tr -d " " |xargs echo $1 >> .hosts
}

run_vagrant(){
    mkdir VAGRANT
    cd ./VAGRANT
    pwd
    ls
    rm -rf .vagrant
    echo NODES $1
    cp ../Vagrantfile.example ./Vagrantfile 
    sed -i -e "s/NODES_NUMBER/$1/g" ./Vagrantfile
    for i in $(seq 1 $1); do mkdir data$i; done 
    vagrant up 

}

run_lxd(){

    lxc launch $2:$3 $1
    lxc list
    lxc list  --columns=n4 |grep eth0|cut -d"(" -f 1 |cut -d "|" -f 2,3 |tr "|" " " > .hosts
    lxc exec $1 -- sh -c "apt install openssh-server -y"
    cat ./ssh/lxd_key.pub | lxc exec $1 -- sh -c "cat >> ~/.ssh/authorized_keys"  
}


check_ansible(){
    lxc list  --columns=4 |grep eth0|cut -d"(" -f 1|cut -d "|" -f 2 > inventory
    mkdir -p /etc/ansible
    touch /etc/ansible/ansible.cfg
    echo -e "[defaults]\n host_key_checking = False" > /etc/ansible/ansible.cfg
    ansible -m ping -i inventory --key-file ./ssh/lxd_key all
}



get_os_info
package_manager
PACKAGES=""

PS3="Select Your Virtualization Technology"$'\n'
options=("vagrant" "lxd" "lxc" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "vagrant")
            wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            echo "you chose choice $REPLY which is $opt"
            PACKAGES=$PACKAGES"curl python3-pip virtualbox ansible vagrant"
            echo -e "default packages are:\n" $PACKAGES "\n if you need add new packge to list Enter the packge name"
            read NEW_PACKGES
            PACKAGES=$PACKAGES" "$NEW_PACKGES
            package_installer $PACKAGES
            echo -e "enter the nodes Number:\n"
            read NODES_NUMBER
            run_vagrant $NODES_NUMBER 
            break
            ;;
        "lxd")
            echo "you chose choice $REPLY which is $opt"
            PACKAGES=$PACKAGES"curl python3-pip virtualbox ansible snapd"
            echo -e "default packages are:\n" $PACKAGES "\n if you need add new packge to list Enter the packge name"
            read NEW_PACKGES
            PACKAGES=$PACKAGES" "$NEW_PACKGES
            package_installer $PACKAGES
            snap install lxd
            echo -e "enter the nodes Number:\n"
            read NODES_NUMBER
            mkdir ./ssh/
            #touch ./ssh/lxd_key
            ssh-keygen -f ./ssh/lxd_key -t ecdsa -b 521 -q -N ""
            lxd init --minimal
            for N in $(seq "$NODES_NUMBER");
            do
                    echo LXD:$N
                    run_lxd container-$N ubuntu 22.04 
            done
            check_ansible
            #make_inventory_for_ansible
            lxc profile create proxy-3000
            lxc profile create proxy-9100
            MONITOR_SERVER_NAME= "$(echo $monitor_server|cut -d ":" -f1)"
            echo $MONITOR_SERVER_NAME
            lxc profile device add proxy-3000 hostport3000 proxy connect="tcp:127.0.0.1:3000" listen="tcp:0.0.0.0:3000"
            lxc profile device add proxy-9100 hostport9100 proxy connect="tcp:127.0.0.1:91000" listen="tcp:0.0.0.0:9100"
            lxc profile add container1 proxy-3000
            lxc profile add container1 proxy-9100
            break
            ;;
        "lxc")
            echo "you chose choice $REPLY which is $opt"
            PACKAGES=$PACKAGES"curl python3-pip virtualbox ansible lxc"
            echo -e "default packages are:\n" $PACKAGES "\n if you need add new packge to list Enter the packge name"
            read NEW_PACKGES
            PACKAGES=$PACKAGES" "$NEW_PACKGES
            package_installer $PACKAGES
            echo -e "enter the nodes Number:\n"
            read NODES_NUMBER
            for N in $(seq "$NODES_NUMBER");
            do
                    echo LXC:$N
                    run_lxc container-$N ubuntu jammy amd64 
            done
            run_lxc
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

