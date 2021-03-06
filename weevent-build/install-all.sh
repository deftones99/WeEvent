#!/bin/bash
#
# install weevent service, support FISCO-BCOS 1.3 and 2.0
#
################################################################################

out_path=""
block_chain_version=
block_chain_channel=
block_chain_node_path=
broker_port=8081

nginx_port=8080

governance=
governance_port=
mysql_ip=
mysql_port=
mysql_user=
mysql_password=

installPWD=$PWD

function yellow_echo (){
    local what=$*
    if true;then
        echo -e "\e[1;33m${what} \e[0m"
    fi
}

function error_message(){
    local message=$1
    echo "ERROR - ${message}"
    exit 1
}

function ini_get(){
    local file="config.ini"
    local section=$1
    local param=$2
    local no_exit=$3
    local value=$($installPWD/build/crudini-0.9/crudini --get $file $section $param 2> /dev/null)
    if [ $? -ne 0 ];then
        if [ "${no_exit}" = "true" ];then
            #{ echo >&2 "ERROR - ini config get failed, section is $section param is $param."; exit 1; }
            echo "no_exit"
        else
            echo "error_message"
            error_message "ERROR - ini config get failed, section is $section param is $param."
        fi
    fi

    echo "$value"
}

function set_global_param(){
    block_chain_version=$(ini_get "fisco-bcos" "version")
    block_chain_channel=$(ini_get "fisco-bcos" "channel")
    block_chain_node_path=$(ini_get  "fisco-bcos" "node_path")
    block_chain_node_path=`realpath $block_chain_node_path`

    nginx_port=$(ini_get "nginx" "port")
    
    broker_port=$(ini_get  "broker" "port")
    
    governance_enable=$(ini_get  "governance" "enable")
    governance_port=$(ini_get "governance" "port")

    mysql_ip=$(ini_get "governance" "mysql_ip")
    mysql_port=$(ini_get  "governance" "mysql_port")
    mysql_user=$(ini_get "governance" "mysql_user")
    mysql_password=$(ini_get "governance" "mysql_password")
}

function check_port(){
    lsof -i:${1}
    
    if [ $? -eq 1 ];then
        echo "$1 port is okay"
    else 
        echo "$1 port is use"
        exit 1
    fi
}

function check_param(){
    if [ -d $block_chain_node_path ]; then
        check_port $broker_port
        check_port $nginx_port
        echo "param ok"
    else
        echo "path not exist, $block_chain_node_path"
        exit 1;
    fi
}

### check the result and print it
function check_result(){
    if [[ $? -eq 0 ]];then
        yellow_echo $1
    else
        exit 1;
   fi
}

function install_module(){
    yellow_echo "install module broker"
    cd $installPWD/modules/broker
    ./install-broker.sh --out_path $out_path/broker --listen_port $broker_port --block_chain_node_path $block_chain_node_path --channel_info $block_chain_channel --version $block_chain_version
    check_result "install broker success"

    yellow_echo "install module nginx"
    cd $installPWD/modules/nginx
    ./install-nginx.sh --nginx_path $out_path/nginx --nginx_port $nginx_port --broker_port $broker_port --governance_port $governance_port
    check_result "install nginx success"

    if [ $governance_enable = "true" ];then
        yellow_echo "install module governance"
        cd $installPWD/modules/governance
        ./install-governance.sh --out_path $out_path/governance --server_port $governance_port --broker_port $broker_port --mysql_ip $mysql_ip --mysql_port $mysql_port --mysql_user $mysql_user --mysql_pwd $mysql_password
        check_result "install governance success"
    fi
}

function install_crudini(){
    yellow_echo "install crudini"

    mkdir -p $installPWD/build/
    tar -zxf $installPWD/third-packages/crudini-0.9.tar.gz -C $installPWD/build/  
       
    $installPWD/build/crudini-0.9/crudini --version
    sleep 1
    if [ $? -ne 0 ];then
        echo "install crudini failed, skip"
        exit 1
    fi
}

function update_check_server(){
    sed -i "s/8080\/weevent/$broker_port\/weevent/" check-service.sh
    sed -i "s/8082\/weevent-governance/$governance_port\/weevent-governance/" check-service.sh
}

function main(){
    # confirm
    if [ -d $2 ]; then
        read -p "$2 already exist, continue? [Y/N]" cmd_input
        if [ "Y" != "$cmd_input" ]; then
            echo "input $cmd_input, install skipped"
            exit 1
        fi
    fi
    mkdir -p $2
    if [ $? -ne 0 ];then
        echo "create path $2 fail !!! "
        exit 1
    fi
    out_path=`realpath $2`

    #crudini
    install_crudini

    # set the params
    set_global_param

    # check the dir is exist or not
    check_param

    # set the check service port
    update_check_server

    # install module
    install_module

    cd $installPWD
    cp start-all.sh check-service.sh stop-all.sh uninstall-all.sh $out_path
}

# Usage message
if [ $# -lt 2 ]; then
    echo "Usage:"
    echo "    ./install-all.sh -p install_path"
    exit 1
fi

main $1 $2
