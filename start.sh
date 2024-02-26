
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
        echo -e "[monitorserver]\n $(echo $monitor_server|cut -d':' -f2)" >> prometheus_inventory


}


prepareHost
install_prometheus
install_node_exporter
install_grafana


