### 介绍

Archlinux的自动化安装脚本

### 使用

#### 将Arch-EFISTUB-Before-Chroot.txt脚本上传执行(bash Arch...),这个脚本主要完成

- **自动分区并格式化**

  *由于每个人的分区和挂载编好不同,所以仍需要稍微调整一下以符合自己的期望*
  
  *本人查询资料许久仍没有找到arch-chroot切换系统时的更多信息,因此在切换系统后仍然需要使用手动上传第二个脚本继续执行*

#### 将Arch-EFISTUB-After-Chroot.txt脚本上传执行,这个脚本主要完成

- **自动安装引导项(EEFISTUB)**

- 安装必要的网络软件包
  - networkmanager 
  - net-tools 
  - openssh 

##### *TIP*

*这两个小脚本可以通过xshell自带的ftp工具或WinSCP上传,也可以直接从远处终端拷贝内容到shell脚本执行*

*执行方式: bash install.sh,install的内容由上述安装脚本内容填充*

