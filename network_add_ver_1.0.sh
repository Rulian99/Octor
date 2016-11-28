#/bin/bash
#新增网卡配置文件
#@author xiangxu698@gamil.com
#Date: 28-11-2016

#全局变量
export config_dev
declare -A Device
declare -a device

####################
#function cmd_test()
#判断系统命令执行结果
#局部变量: cmd、result
#全局变量: None
#返回值： None
####################

function cmd_test(){
local  cmd=$@
eval $cmd
local result=$?
[[ $result -ne 0 ]] && echo "excute error! " 
exit 1
}

###################
#function dev_list()
#网卡列表
#局部变量：index,dev_num_cmd,dev_name
#全局变量：device
#返回值：device
###################

function dev_list(){
local index=0
local dev_num_cmd="sudo ip addr show | grep -P '^\d'  | cut -d ':' -f 1 |wc -l"
local dev_name="sudo ip addr show | grep -P '^\d'  | cut -d ':' -f 2"

dev_num=$(cmd_test $dev_num_cmd)
dev_name=$(cmd_test $dev_name)

for it in  $(echo $dev_name)
    do
      index=$((${index}+1))
      device[$index]=$it
      echo $index: ${device[$index]}
    done
return $device
}

#############################
#function dev_config_list
#Debian系列网卡配置参数
#局部变量：dev_items, dev
#全局变量：device
#返回值： None
#############################

function dev_config_list(){
local dev_items=("address" "gateway" "netmask" "network" "dns")
local dev
local result

dev_list

local list_len=${#device[@]}
read -p "please input the number of network card: " dev
[[ $dev -le $list_len && $dev -ge 1 ]]
while [ $? -ne 0 ]
    do
       echo "out of the range,input again!!"
       read -p "please input the number of network card: " dev
       [[ $dev -le $list_len && $dev -ge 1 ]]
    done

for item in ${dev_items[@]}
    do
       read -p "please finish $item: " Device[$item]
       IP_check ${Device[$item]}
       result=$?
       while (($result !=0))
            do
                echo "input error!! input again!"
                read -p "please finish $item: " Device[$item]
                IP_check ${Device[$item]}
                result=$?
            done
    done

echo "The information list"
echo "device: ${device[$dev]}"
for item in ${!Device[*]}
    do
        echo "$item  =  ${Device[$item]}"
    done
config_dev=${device[$dev]}
}

#################################
#Redhat系列网卡配置参数
#
#################################

function rhel_dev_config_list(){
local dev_items=("IPADDR"  "GATEWAY" "NETMASK" "DNS1")
local dev
local result
dev_list

read -p "please input the number of network card: " dev

for item in ${dev_items[@]}
    do
       read -p "please finish $item: " Device[$item]
       IP_check ${Device[$item]}
#       while (($result != 0 ))
#          do
#              read -p "please finish $item: " Device[$item]
#              result=$(IP_check ${Device[$item]})
#          done
       [[ $? -eq 0  ]] && echo "yes" || echo "no"
    done

echo "The information list"
echo "device: ${device[$dev]}"
for item in ${!Device[*]}
    do
        echo "$item  =  ${Device[$item]}"
    done
config_dev=${device[$dev]}
}

#################################
#function dev_config
#网卡参数确认
#局部变量： dev_name,notice,choice,headline,line1,line2
#全局变量：config_dev
#返回值： None
################################

function  dev_config(){

dev_config_list

local dev_name=$config_dev
local notice="please input [Yes/No]?"
local choice
local headline="#The Internal network interface"
local line1="auto $config_dev"
local line2="iface  $config_dev inet static"

while true
    do
        read -p "$notice" choice
        if [ "$choice" = "Yes" -o "$choice" = "yes" ]; then
            echo $headline > interfaces
            echo $line1 >> interfaces
            echo $line2 >> interfaces
            
            for item in ${!Device[*]}
                do
                     echo "$item  ${Device[$item]}" >> interfaces
                done 
            echo "please restart network"
            break
        elif [ "$chioce" = "No" -o "$choice" = "no" ]; then

            dev_config_list

        else
            echo "Input error!! please input again"
        fi

    done

}

##########################
#function IP_check
#网络IP正则匹配
#局部变量： arg, ip_pattern
#全局变量： None
#返回值： None
#########################

function IP_check(){
local arg=$@
local ip_pattern="^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
#local flag=0

[[ $arg =~ $ip_pattern ]]
}

dev_config
