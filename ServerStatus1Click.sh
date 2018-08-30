#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 6+/Debian 6+/Ubuntu 14.04+/others(test)
#	Description: Auto-install the ServerStatus Client
#	Version: 1.2.0
#	Author: dovela
#=================================================

sh_ver="1.2.0"
file="/home/ServerStatus"
status_linux="/home/ServerStatus/clients/client-linux.py"
status_psutil="/home/ServerStatus/clients/client-psutil.py"
client_log_file="/home/ServerStatus/client.log"

check_pid(){
	PID=`ps -ef | grep -v grep | grep client-linux.py | awk '{print $2}'` && run_mode="linux"
    [[ -z ${PID} ]] && PID=`ps -ef | grep -v grep | grep client-psutil.py | awk '{print $2}'` && run_mode="psutil"
}

read_para(){
	server=`awk '{if($0~"SERVER") print}' ${status_linux} | sed 's/"/ /g' | awk '{print $3}' | head -n 1`
	port=`awk '{if($0~"PORT") print}' ${status_linux} | awk '{print $3}' | head -n 1`
	user=`awk '{if($0~"USER") print}' ${status_linux} | sed 's/"/ /g' | awk '{print $3}' | head -n 1`
	passwd=`awk '{if($0~"PASSWORD") print}' ${status_linux} | sed 's/"/ /g' | awk '{print $3}' | head -n 1`
	p_server=`awk '{if($0~"SERVER") print}' ${status_psutil} | sed 's/"/ /g' | awk '{print $3}' | head -n 1`
	p_port=`awk '{if($0~"PORT") print}' ${status_psutil} | awk '{print $3}' | head -n 1`
	p_user=`awk '{if($0~"USER") print}' ${status_psutil} | sed 's/"/ /g' | awk '{print $3}' | head -n 1`
	p_passwd=`awk '{if($0~"PASSWORD") print}' ${status_psutil} | sed 's/"/ /g' | awk '{print $3}' | head -n 1`
}

check_sys(){
	 if [[ -f /etc/redhat-release ]]; then
		release="centos"
	 elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	 elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	 elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	 elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	 elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	 elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
         fi
	bit=`uname -m`
}

centos_yum(){
	yum install -y epel-release && yum clean all && yum update
    yum install -y git python-pip gcc python-devel
}

debian_apt(){
	apt-get install -y git python-setuptools python-dev build-essential python-pip
}

get_para(){
	stty erase '^H' && read -p " 服务端地址:" sserver
    stty erase '^H' && read -p " 远程端口(默认35601):" sport
	[[ -z ${sport} ]] && sport="35601"
  	stty erase '^H' && read -p " 客户端username:" suser
  	stty erase '^H' && read -p " 客户端password:" spasswd
}

replace_para(){
    sed -i -e "s/${server}/${sserver}/g" ${status_linux}
	sed -i -e "s/${port}/${sport}/g" ${status_linux}
  	sed -i -e "s/${user}/${suser}/g" ${status_linux}
  	sed -i -e "s/${passwd}/${spasswd}/g" ${status_linux}
 	sed -i -e "s/${p_server}/${sserver}/g" ${status_psutil}
	sed -i -e "s/${p_port}/${sport}/g" ${status_psutil}
  	sed -i -e "s/${p_user}/${suser}/g" ${status_psutil}
  	sed -i -e "s/${p_passwd}/${spasswd}/g" ${status_psutil}
}

install_ssc(){
    clear
    get_para
   	clear
  	cd /home && git clone https://github.com/cppla/ServerStatus.git && cd ServerStatus
  	echo 'ServerStatus客户端安装完成'
	read_para
  	replace_para
    clear
	echo ' ServerStatus客户端配置完成，请进行下一步'
	echo ' 1. 运行 client-linux'
	echo ' 2. 运行 client-psutil'
	stty erase '^H' && read -p " 请输入数字 [1-2]:" num
	 case "$num" in
 		1)
		run_linux
		;;
		2)
		run_psutil
		;;
    esac
    cd #
}

delete_ssc(){
	check_pid
	[[ ! -z ${PID} ]] && kill -9 ${PID}
	rm -rf ${file}
	echo -e 'ServerStatus客户端已卸载!'
}

run_linux(){
	check_pid
	[[ ! -z ${PID} ]] && echo -e 'ServerStatus 客户端运行中!' && exit 1
	nohup python ${status_linux} > ${client_log_file} 2>&1 &
  	echo -e 'ServerStatus-linux客户端已开始运行'
}

run_psutil(){
	check_pid
	[[ ! -z ${PID} ]] && echo -e 'ServerStatus 客户端运行中!' && exit 1
	nohup python ${status_psutil} > ${client_log_file} 2>&1 &
  	echo -e 'ServerStatus-psutil客户端已开始运行'
}

stop_client(){
	check_pid
	[[ -z ${PID} ]] && echo -e "Error, ServerStatus 客户端没有运行 !" && exit 1
	kill -9 ${PID}
}

install_env(){
	 clear
	  if [[ ${release} == "centos" ]]; then
		centos_yum
	  else
		debian_apt
	  fi
	pip install --upgrade
	pip install psutil
	echo '依赖环境安装完成，请再次运行脚本'
}

update_ssc(){
    cd ${file}
    git pull
    update_judge=`git status | awk '{if($0~"git pull") print}'`
    if [[ -z "${update_judge}" ]]; then
        echo '当前 ServerStatus 为最新版本,不需更新!'
    else
        clear
        stty erase '^H' && read -p "检测到新版本 ServerStatus ,输入任意键开始更新" dovela
        stop_client
        clear
        read_para
        sserver=${server} && sport=${port} && suser=${user} && spasswd=${passwd}
        git fetch --all && git reset --hard origin/master
        read_para
        replace_para
        if [[ ${run_mode} == "psutil" ]]; then
            run_psutil
        else
            run_linux
        fi
        echo ' ServerStatus客户端升级完毕，已自动重启'
    fi
    cd #
}

 clear
check_sys
[ $(id -u) != "0" ] && echo -e "Error: You must be root to run this script" && exit 1
echo -e " 出现问题请在 https://github.com/dovela/ServerStatus1Click 处提issue
    当前版本:${sh_ver}
————————————
  1.首次安装并启动 ServerStatus 客户端
  2.运行 client_linux
  3.运行 client_psutil
  4.停止运行
  5.首次安装linux依赖，直接安装失败请执行
  6.卸载 ServerStatus
————————————
  7.更新 ServerStatus
————————————
  输入数字开始，或ctrl + c退出
"
echo && stty erase '^H' && read -p " 请输入数字[1-7]:" num
 case "$num" in
 	1)
	install_ssc
	;;
	2)
	run_linux
	;;
	3)
	run_psutil
	;;
	4)
	stop_client
	;;
	5)
	install_env
	;;
	6)
	delete_ssc
	;;
    7)
    update_ssc
    ;;
	*)
	echo -e "Error, 请输入正确的数字 [1-6]!"
	;;
esac
