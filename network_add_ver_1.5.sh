#/bin/bash
#新增网卡配置文件
#@author xiangxu698@gamil.com
#Date: 28-11-2016

#全局变量
export config_dev
export CONFIG_FILE="/etc/network/interfaces"
export BACKUP_FILE="/etc/network/interfaces.bak"
declare -A Device
declare -a device

###################
#functon menu()
#打印help菜单
#全局变量:None
#局部变量:None
#返回值:None
###################

function menu(){
echo  -e "\t-e excute command to configuring network 
      \t-r rollback   
      \t-h help "

}

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
[[ $result -ne 0 ]] && echo -e "\033[31mExcute error!\033[0m" 
#exit 1
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
read -p "Please input the number of network card: " dev
[[ $dev -le $list_len && $dev -ge 1 ]]
while [ $? -ne 0 ]
    do
       echo -e "\033[31mOut of the range,input again!!\033[0m"
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
                echo -e "\033[31mInput error!! input again!\033[0m"
                read -p "please finish $item: " Device[$item]
                IP_check ${Device[$item]}
                result=$?
            done
    done
echo -e "\033[33m########################################\033[0m"
echo  "The information list"
printf  "%-20s%s\n" device ${device[$dev]}
for item in ${!Device[*]}
    do
        printf   "%-20s%s\n" $item ${Device[$item]}
    done
echo -e "\033[33m########################################\033[0m"
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

local cmd1="sudo cp $CONFIG_FILE $BACKUP_FILE"
local cmd2="sudo mv $BACKUP_FILE /etc/network/$(date +"%Y-%m-%d-%H-%M").interfaces.bak"
local dev_name=$config_dev
local notice="please input [Yes/No]? "
local choice
local headline="#The Internal network interface"
local line1="auto $config_dev"
local line2="iface  $config_dev inet static"

if [ ! -e $BACKUP_FILE ]; then
    cmd_test $cmd1
else
    cmd_test $cmd2
    cmd_test $cmd1
fi

while true
    do
        read -p "$notice" choice
        if [ "$choice" = "Yes" -o "$choice" = "yes" ]; then
            sudo echo $headline > interface
            sudo echo $line1 >> interface
            sudo echo $line2 >> interface
            
            for item in ${!Device[*]}
                do
                    sudo  echo "$item  ${Device[$item]}" >> interface
                done 
            echo "restart networking....."
            break
        elif [ "$chioce" = "No" -o "$choice" = "no" ]; then

            dev_config_list

        else
            echo -e "\033[31mInput error!! please input again\033[0m"
        fi

    done
network_restart
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

#########################
#function network_restart
#重启网络，使新添加网卡配置生效
#全局变量:None
#局部变量:cmd
#返回值:None
#########################

function network_restart(){
local cmd="sudo ifup $config_dev "
#local cmd="sudo cp $CONFIG_FILE $BACKUP_FILE"
cmd_test $cmd
}

#########################
#function rollback()
#回滚网络配置并重启网络
#全局变量:CONFIG_FILE, BACKUP_FILE
#局部变量:cmd_1,cmd_2
#返回值:None
#########################

function rollback(){
local cmd_1="sudo cp $BACKUP_FILE $CONFIG_FILE"
local cmd_2="sudo /etc/init.d/networking restart" 
cmd_test $cmd_1
cmd_test $cmd_2 2>&1 > /dev/null
}

#########################
#function main()
#用户执行主菜单
#全局变量:None
#局部变量:None
#返回值:None
#########################

function main(){
while getopts "e,r,h" opt; do
  case $opt in
  e)
    dev_config
    ;;
  r)
    echo "Network restarting..."
    rollback
    ;;
  h)
    menu
    ;;
  *)
    echo "sh test.sh -h to help"
    ;;
  esac
done
}

if [ ! $UID = 0 ] ; then
  echo "Please change to root" 
else
   main $1
   [[ $# = 0 ]] && echo "Usage: sh test.sh or ./test.sh -h for help"
fi
