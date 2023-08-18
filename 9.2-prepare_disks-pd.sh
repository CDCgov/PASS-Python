# https://learn.microsoft.com/en-us/azure/virtual-machines/linux/attach-disk-portal?tabs=ubuntu


lsblk -o NAME,HCTL,SIZE,MOUNTPOINT | grep -i "sd"

sudo parted /dev/sdb --script mklabel gpt mkpart xfspart xfs 0% 100%
sleep 3
sudo mkfs.xfs /dev/sdb1 -f
sleep 3
sudo partprobe /dev/sdb1 

sudo parted /dev/sdc --script mklabel gpt mkpart xfspart xfs 0% 100%
sleep 3
sudo mkfs.xfs /dev/sdc1 -f
sleep 3
sudo partprobe /dev/sdc1

sudo parted /dev/sdd --script mklabel gpt mkpart xfspart xfs 0% 100%
sleep 3
sudo mkfs.xfs /dev/sdd1 -f
sleep 3
sudo partprobe /dev/sdd1

lsblk -o NAME,HCTL,SIZE,MOUNTPOINT | grep -i "sd"

sudo mkdir /mnt/cache1
sudo mkdir /mnt/temp
sudo mkdir /mnt/cache2

#sudo blkid

