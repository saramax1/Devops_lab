
#!/bin/bash
install_prometheus(){
        echo "hi prometheus"
}
install_grafana(){
        echo "hi grafana"
}
install_node_exporter(){
        echo "hi node exporter"
}

prepareHost(){
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
        lxc profile create proxy-3000
        lxc profile create proxy-9100
        MONITOR_SERVER_NAME= "$(echo $monitor_server|cut -d ":" -f1)"
        echo $MONITOR_SERVER_NAME
        lxc profile device add proxy-3000 hostport3000 proxy connect="tcp:127.0.0.1:3000" listen="tcp:0.0.0.0:3000"
        lxc profile device add proxy-9100 hostport9100 proxy connect="tcp:127.0.0.1:91000" listen="tcp:0.0.0.0:9100"
        lxc profile add container1 proxy-3000
        lxc profile add container1 proxy-9100
        
}


prepareHost
install_prometheus
install_node_exporter
install_grafana


