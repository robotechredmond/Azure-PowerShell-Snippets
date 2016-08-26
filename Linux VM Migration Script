cat /etc/issue
uname –-all

# run apt-get update then apt-get upgrade
# apt-get update updates the list of available packages and their versions, but it does not install or upgrade any packages.
# apt-get upgrade actually installs newer versions of the packages you have. After updating the lists, the package manager knows about available updates for the software you have installed. This is why you first want to update.

sudo apt-get update
sudo apt-get upgrade

sudo apt-get install rsync
sudo apt-get install screen

sudo groupadd -g 500 AzureAdmin
sudo useradd -u 500 -g 500 -m -s /bin/bash AzureAdmin
sudo passwd AzureAdmin 

sudo screen -S AzureMigration

sudo screen -r

EXCLUDEFILE=/tmp/exclude.file
EXCLUDELIST='/boot /etc/fstab /etc/hostname /etc/issue /etc/hosts /etc/sudoers /etc/networks /etc/network/* /etc/resolv.conf /etc/ssh/* /etc/sysctl.conf /etc/mtab /etc/udev/rules.d/* /lock /net /tmp' 
EXCLUDEPATH=$(echo $EXCLUDELIST | sed 's/\ /\\n/g') 
echo -e $EXCLUDEPATH > $EXCLUDEFILE 
find / -name '*cloud-init*' >> $EXCLUDEFILE 
find / -name '*cloud-config*' >> $EXCLUDEFILE 
find / -name '*cloud-final*' >> $EXCLUDEFILE

sudo service apache2 stop

sudo -s
TARGETVM="insert_target_vm_public_ip_address"
TARGETVM="13.76.102.125"
rsync --rsh="ssh" --exclude-from="$EXCLUDEFILE" --rsync-path="sudo rsync" --verbose --progress -rlpEAXogDtSzhPx / AzureAdmin@$TARGETVM:/ 
rsync --rsh="ssh" --exclude-from="$EXCLUDEFILE" --rsync-path="sudo rsync" --verbose --progress -crlpEAXogDtSzhPx / AzureAdmin@$TARGETVM:/

ssh AzureAdmin@$TARGETVM 
sudo shutdown -r now