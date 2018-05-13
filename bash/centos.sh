#!/bin/bash

while [[ $# -ge 1 ]]; do
  case $1 in
    -p|--password)
      shift
      WDtmp="$1"
      shift
      ;;
    *)
      echo -ne " Usage:\n\tbash $0\t-p/--password (default xiaofd.win) \n"
      exit 1;
      ;;
    esac
  done

[ $EUID -ne 0 ] && echo "Error:This script must be run as root!" && exit 1

[ -n $WDtmp ] && myPASSWORD="$WDtmp"
[ -z $myPASSWORD ] && myPASSWORD='xiaofd.win'

clear && echo -e "\n\033[36m# Install\033[0m\n"

echo -e "\n[\033[33m$vDEB\033[0m] [\033[33m$VER\033[0m] Downloading..."
CentOSMirror="http://mirror.centos.org/centos-6/6.9/os/x86_64/isolinux"
mkdir -p /xiaofd
wget --no-check-certificate -qO '/xiaofd/initrd.img' "$CentOSMirror/initrd.img"
[ $? -ne '0' ] && echo -ne "\033[31mError! \033[0mDownload 'initrd.img' failed! \n" && exit 1
wget --no-check-certificate -qO '/xiaofd/vmlinuz' "$CentOSMirror/vmlinuz"
[ $? -ne '0' ] && echo -ne "\033[31mError! \033[0mDownload 'vmlinuz' failed! \n" && exit 1

DEFAULTNET="$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.*' |head -n1 |sed 's/proto.*\|onlink.*//g' |awk '{print $NF}')"
[ -n "$DEFAULTNET" ] && IPSUB="$(ip addr |grep ''${DEFAULTNET}'' |grep 'global' |grep 'brd' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}/[0-9]\{1,2\}')"
IPv4="$(echo -n "$IPSUB" |cut -d'/' -f1)"
NETSUB="$(echo -n "$IPSUB" |grep -o '/[0-9]\{1,2\}')"
GATE="$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}')"
[ -n "$NETSUB" ] && MASK="$(echo -n '128.0.0.0/1,192.0.0.0/2,224.0.0.0/3,240.0.0.0/4,248.0.0.0/5,252.0.0.0/6,254.0.0.0/7,255.0.0.0/8,255.128.0.0/9,255.192.0.0/10,255.224.0.0/11,255.240.0.0/12,255.248.0.0/13,255.252.0.0/14,255.254.0.0/15,255.255.0.0/16,255.255.128.0/17,255.255.192.0/18,255.255.224.0/19,255.255.240.0/20,255.255.248.0/21,255.255.252.0/22,255.255.254.0/23,255.255.255.0/24,255.255.255.128/25,255.255.255.192/26,255.255.255.224/27,255.255.255.240/28,255.255.255.248/29,255.255.255.252/30,255.255.255.254/31,255.255.255.255/32' |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'${NETSUB}'' |cut -d'/' -f1)"

[ -n "$GATE" ] && [ -n "$MASK" ] && [ -n "$IPv4" ] || {
echo "Not found \`ip command\`, It will use \`route command\`."
ipNum() {
  local IFS='.'
  read ip1 ip2 ip3 ip4 <<<"$1"
  echo $((ip1*(1<<24)+ip2*(1<<16)+ip3*(1<<8)+ip4))
}

SelectMax(){
ii=0
for IPITEM in `route -n |awk -v OUT=$1 '{print $OUT}' |grep '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'`
  do
    NumTMP="$(ipNum $IPITEM)"
    eval "arrayNum[$ii]='$NumTMP,$IPITEM'"
    ii=$[$ii+1]
  done
echo ${arrayNum[@]} |sed 's/\s/\n/g' |sort -n -k 1 -t ',' |tail -n1 |cut -d',' -f2
}

[[ -z $IPv4 ]] && IPv4="$(ifconfig |grep 'Bcast' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' |head -n1)"
[[ -z $GATE ]] && GATE="$(SelectMax 2)"
[[ -z $MASK ]] && MASK="$(SelectMax 3)"

[ -n "$GATE" ] && [ -n "$MASK" ] && [ -n "$IPv4" ] || {
echo "Error! Not configure network. "
exit 1
}
}

[ -f /etc/network/interfaces ] && {
[[ -z "$(sed -n '/iface.*inet static/p' /etc/network/interfaces)" ]] && AutoNet='1' || AutoNet='0'
[ -d /etc/network/interfaces.d ] && {
ICFGN="$(find /etc/network/interfaces.d -name '*.cfg' |wc -l)" || ICFGN='0'
[ "$ICFGN" -ne '0' ] && {
for NetCFG in `ls -1 /etc/network/interfaces.d/*.cfg`
 do 
  [[ -z "$(cat $NetCFG | sed -n '/iface.*inet static/p')" ]] && AutoNet='1' || AutoNet='0'
  [ "$AutoNet" -eq '0' ] && break
done
}
}
}
[ -d /etc/sysconfig/network-scripts ] && {
ICFGN="$(find /etc/sysconfig/network-scripts -name 'ifcfg-*' |grep -v 'lo'|wc -l)" || ICFGN='0'
[ "$ICFGN" -ne '0' ] && {
for NetCFG in `ls -1 /etc/sysconfig/network-scripts/ifcfg-* |grep -v 'lo$' |grep -v ':[0-9]\{1,\}'`
 do 
  [[ -n "$(cat $NetCFG | sed -n '/BOOTPROTO.*[dD][hH][cC][pP]/p')" ]] && AutoNet='1' || {
  AutoNet='0' && . $NetCFG
  [ -n $NETMASK ] && MASK="$NETMASK"
  [ -n $GATEWAY ] && GATE="$GATEWAY"
}
  [ "$AutoNet" -eq '0' ] && break
done
}
}

DEFAULTNET=eth0
[ "$AutoNet" -eq '1' ] && {
NetCMD="network  --bootproto=dhcp --device=$DEFAULTNET --onboot=on"
}
[ "$AutoNet" -eq '0' ] && {
NetCMD="network  --bootproto=static --device=$DEFAULTNET --gateway=$GATEWAY --ip=$IPv4 --nameserver=8.8.8.8 --netmask=$MASK --onboot=on"
}

cat >/xiaofd/ks.cfg<<EOF
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Firewall configuration
firewall --disabled
# Install OS instead of upgrade
install
# Use network installation
url --url="http://mirror.centos.org/centos-6/6.9/os/x86_64/"
# url --url="http://mirrors.163.com/centos/6.9/os/x86_64/"
# Root password
rootpw --plaintext xiaofd.win
# System authorization information
auth  --useshadow  --passalgo=sha512
# Use graphical install
graphical
firstboot --disable
# System keyboard
keyboard us
# System language
lang en_US
# SELinux configuration
selinux --disabled
# Installation logging level
logging --level=info
# Reboot after installation
reboot
# System timezone
timezone  Asia/Shanghai
# Network information
$NetCMD
# network  --bootproto=dhcp --device=eth0 --onboot=on
# network  --bootproto=static --device=eth1 --gateway=127.0.0.1 --ip=127.0.0.2 --nameserver=8.8.8.8 --netmask=255.255.255.0 --onboot=on
# System bootloader configuration
bootloader --append="crashkernel=auto rhgb quiet" --location=mbr
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel 
# Disk partitioning information
part swap --fstype="swap" --recommended
part / --fstype="ext4" --grow --size=1

%post --interpreter=/bin/bash
yum update -y && yum install -y openssh-server
%end

%packages
@base
@chinese-support

%end
EOF

DEVPATH=`df -lh | grep /$ | cut -d " " -f 1 | cut -d "/" -f 3`

[ -f /boot/grub/grub.cfg ] && GRUBOLD='0' && GRUBDIR='/boot/grub' && GRUBFILE='grub.cfg'
[ -z $GRUBDIR ] && [ -f /boot/grub2/grub.cfg ] && GRUBOLD='0' && GRUBDIR='/boot/grub2' && GRUBFILE='grub.cfg'
[ -z $GRUBDIR ] && [ -f /boot/grub/grub.conf ] && GRUBOLD='1' && GRUBDIR='/boot/grub' && GRUBFILE='grub.conf'
[ -z $GRUBDIR -o -z $GRUBFILE ] && echo "Error! Not Found grub path." && exit 1

[ ! -f $GRUBDIR/$GRUBFILE ] && echo "Error! Not Found $GRUBFILE. " && exit 1

[ ! -f $GRUBDIR/$GRUBFILE.old ] && [ -f $GRUBDIR/$GRUBFILE.bak ] && mv -f $GRUBDIR/$GRUBFILE.bak $GRUBDIR/$GRUBFILE.old
mv -f $GRUBDIR/$GRUBFILE $GRUBDIR/$GRUBFILE.bak
[ -f $GRUBDIR/$GRUBFILE.old ] && cat $GRUBDIR/$GRUBFILE.old >$GRUBDIR/$GRUBFILE || cat $GRUBDIR/$GRUBFILE.bak >$GRUBDIR/$GRUBFILE

[ "$GRUBOLD" == '0' ] && {
CFG0="$(awk '/menuentry /{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
CFG2="$(awk '/menuentry /{print NR}' $GRUBDIR/$GRUBFILE|head -n 2 |tail -n 1)"
CFG1=""
for CFGtmp in `awk '/}/{print NR}' $GRUBDIR/$GRUBFILE`
 do
  [ $CFGtmp -gt "$CFG0" -a $CFGtmp -lt "$CFG2" ] && CFG1="$CFGtmp";
 done
[ -z "$CFG1" ] && {
echo "Error! read $GRUBFILE. "
exit 1
}
sed -n "$CFG0,$CFG1"p $GRUBDIR/$GRUBFILE >/tmp/grub.new
[ -f /tmp/grub.new ] && [ "$(grep -c '{' /tmp/grub.new)" -eq "$(grep -c '}' /tmp/grub.new)" ] || {
echo -ne "\033[31mError! \033[0mNot configure $GRUBFILE. \n"
exit 1
}

sed -i "/menuentry.*/c\menuentry\ \'Install OS \[$vDEB\ $VER\]\'\ --class debian\ --class\ gnu-linux\ --class\ gnu\ --class\ os\ \{" /tmp/grub.new
[ "$(grep -c '{' /tmp/grub.new)" -eq "$(grep -c '}' /tmp/grub.new)" ] || {
echo "Error! configure append $GRUBFILE. "
exit 1
}
sed -i "/echo.*Loading/d" /tmp/grub.new
}

[ "$GRUBOLD" == '1' ] && {
CFG0="$(awk '/title /{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
CFG1="$(awk '/title /{print NR}' $GRUBDIR/$GRUBFILE|head -n 2 |tail -n 1)"
[ -n $CFG0 ] && [ -z $CFG1 -o $CFG1 == $CFG0 ] && sed -n "$CFG0,$"p $GRUBDIR/$GRUBFILE >/tmp/grub.new
[ -n $CFG0 ] && [ -z $CFG1 -o $CFG1 != $CFG0 ] && sed -n "$CFG0,$CFG1"p $GRUBDIR/$GRUBFILE >/tmp/grub.new
[ ! -f /tmp/grub.new ] && echo "Error! configure append $GRUBFILE. " && exit 1
sed -i "/title.*/c\title\ \'Install OS \[$vDEB\ $VER\]\'" /tmp/grub.new
sed -i '/^#/d' /tmp/grub.new
}

[ -n "$(grep 'initrd.*/' /tmp/grub.new |awk '{print $2}' |tail -n 1 |grep '^/boot/')" ] && Type='InBoot' || Type='NoBoot'

LinuxKernel="$(grep 'linux.*/' /tmp/grub.new |awk '{print $1}' |head -n 1)"
[ -z $LinuxKernel ] && LinuxKernel="$(grep 'kernel.*/' /tmp/grub.new |awk '{print $1}' |head -n 1)"
LinuxIMG="$(grep 'initrd.*/' /tmp/grub.new |awk '{print $1}' |tail -n 1)"

[ "$Type" == 'InBoot' ] && {
sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/xiaofd\/vmlinuz ks=hd:$DEVPATH:\/xiaofd\/ks.cfg" $GRUBDIR/$GRUBFILE
sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/xiaofd\/initrd.img" $GRUBDIR/$GRUBFILE
}

[ "$Type" == 'NoBoot' ] && {
sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/vmlinuz ks=hd:$DEVPATH:\/xiaofd\/ks.cfg" $GRUBDIR/$GRUBFILE
sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/initrd.img" $GRUBDIR/$GRUBFILE
}

# sed -i '$a\\n' /tmp/grub.new

chown root:root $GRUBDIR/$GRUBFILE
chmod 444 $GRUBDIR/$GRUBFILE

sleep 3 && reboot >/dev/null 2>&1
