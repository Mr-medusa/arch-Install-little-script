#!/bin/bash
## 友情提示:
## 如果发现报错可使用vim在命令行模式键入":set fileformat=unix"转为linux文件即可
## 
## 我只单独分了root分区,使用的是UEFI所以不需要boot分区,而是esp分区
## 
## 由于每个人的分区和挂载编好不同,所以仍需要稍微调整一下以符合自己的期望
## 此脚本需要修改以下内容的Parted Table部分



## -----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
## -----+-----+-----+-----				安装小脚本				 -----+-----+-----+-----+-----+
## -----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+






## ===============================================================================================
## |						 被安装的磁盘 		  			       						     |
## ===============================================================================================
disk="sda"
## ===============================================================================================
## |						 Root分区所在位置,默认为分区3(sda3) 		  			                 |
## ===============================================================================================
homePart="2"
rootPart="3"








info(){
	  echo "-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+"
	  printf "%-40s %-28s %40s\n" "-----+" "${1}" "-----+"
	  echo "-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+"
}
read -p "确定你要安装的磁盘是[n/y]:$disk,如果不是请修改后继续 " isTheDisk
if [ "$isTheDisk" == "n" ]
	then
		info "退出安装"
		exit
fi
info "安装开始"

## 设置时区同步
timedatectl set-ntp true

## 											清空分区
## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
devNames=`lsblk -lo name| grep $disk`
function clearDevParts
{
	rex="^$disk[0-9]$"
	while test $# -gt 0
		do
		result=$(echo $1 | grep $rex )
		if [[ "$result" != "" ]]
			then
			echo "正在删除: $1 分区"
			rmPart=$1
			eval "parted /dev/$disk rm ${rmPart: -1}" 
		fi
		shift
	done
}
clearDevParts $devNames
## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


## =============================================================================================
## |							 Parted Table 		   				           				   |
## =============================================================================================
echo "yes" | parted "/dev/$disk" mklabel gpt
## esp分区
parted "/dev/$disk" mkpart primary fat32 1M 160M
## home分区
parted "/dev/$disk" mkpart primary ext4 160M 10G
## 根分区		
parted "/dev/$disk" mkpart primary ext4 10G 100%		
parted "/dev/$disk" set 1 boot on

## 

info 格式化开始
eval "mkfs.fat -F32 /dev/${disk}1 && mkfs.ext4 /dev/${disk}${rootPart} && mkfs.ext4 /dev/${disk}${homePart}"

## 								挂载分区这里调整	
## -----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+					
eval "mount /dev/${disk}${rootPart} /mnt && mkdir -p /mnt/boot && mount /dev/${disk}1 /mnt/boot && mkdir -p /mnt/home && mount /dev/${disk}${homePart} /mnt/home"					  	
## -----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+	

lsblk

read -p "确定分区正确[n/y]: " isAllRight
if [ "$isAllRight" == "n" ]
	then
		info "退出安装"
		exit
fi

info 格式化结束
## =============================================================================================
## |							 Parted Table 		   				           				   |
## =============================================================================================


## 											设置镜像
## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wget -O /etc/pacman.d/mirrorlist "http://www.archlinux.org/mirrorlist/?country=CN&protocol=https&ip_version=4"
sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist && cat /etc/pacman.d/mirrorlist
## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


## 											安装软件包
## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
info 安装软件包开始
pacstrap /mnt base base-devel linux 
info 安装软件包结束
## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

## 配置系统
genfstab -U /mnt >> /mnt/etc/fstab
lsblk
info ''

## 											切换到磁盘并设置分区
## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

archroot(){
	info "$1 Start"
	arch-chroot /mnt /bin/bash -c "$2"
	info "$1 End"
}

partuuid=""
findpart_uuid(){
	while read line
	do
		strA=$line
	## =============================================================================================
	## |						 Root分区所在位置,默认为磁盘的分区3 		  			       |
	## =============================================================================================
		strB="${disk}${rootPart}"
	## ---------------------------------------------------------------------------------------------
	## ---------------------------------------------------------------------------------------------
		
		result=$(echo $strA | grep "${strB}")
		if [[ "$result" != "" ]]
		then
			partuuid=$(echo $line| cut -f 1 -d " ")
			echo "=============================找到partuuid：===================================="
			info "partuuid: $partuuid"
		fi
	done<./lsblk.txt
}

## -----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
## ================================================================================================
## |							 arch-chroot start		   				           			      |
## ================================================================================================
## -----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
archroot "设置时区" "ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && hwclock --systohc"
archroot "修改HOSTNAME" "echo \"Arch\" > /etc/hostname" 
archroot "修改HOSTS" "printf \"127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.0.1\tarchlinux.localdomain archlinux\" > /etc/hosts" 
archroot "设置语言" "sed -i \"s/#en_US.UTF-8/en_US.UTF-8/g\" /etc/locale.gen && sed -i \"s/#zh_CN.UTF-8/zh_CN.UTF-8/g\" /etc/locale.gen && locale-gen" 
archroot "编辑locale.conf" "echo \"LANG=en_US.UTF-8\">/etc/locale.conf" 
lsblk -o PARTUUID,NAME,MOUNTPOINT>./lsblk.txt
## 											获取partuuid				
## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
info 获取partuuid
findpart_uuid
execEfiBoot="efibootmgr --disk /dev/$disk --part 1 --create --label \"Arch Linux\" --loader /vmlinuz-linux --unicode 'root=PARTUUID=$partuuid rw selinux=0 initrd=/initramfs-linux.img' --verbose"
## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
archroot "安装引导程序" "pacman -S --noconfirm efibootmgr" 
info "execEfiBoot: $execEfiBoot"
archroot "执行安装引导程序" "$execEfiBoot"
info 安装引导程序结束
archroot "安装网络软件开始" "pacman -S --noconfirm networkmanager net-tools openssh && systemctl enable NetworkManager && systemctl enable sshd"
archroot "配置SSHD" "sed -i \"s/#PermitRootLogin prohibit-password/PermitRootLogin yes/\" /etc/ssh/sshd_config"
archroot "验证条目开始" "efibootmgr --verbose"
## -----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
## ================================================================================================
## |							 arch-chroot end		   				           			      |
## ================================================================================================
## -----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+


rm -rf ./lsblk.txt 

info 安装完成

umount -R /mnt







