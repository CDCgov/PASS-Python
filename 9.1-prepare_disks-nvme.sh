# https://learn.microsoft.com/en-us/azure/virtual-machines/linux/attach-disk-portal?tabs=ubuntu


lsblk -o NAME,HCTL,SIZE,MOUNTPOINT 

sudo parted /dev/nvme0n1 --script mklabel gpt mkpart xfspart xfs 0% 100% 
sleep 3
sudo mkfs.xfs /dev/nvme0n1p1 -f
sleep 3
sudo partprobe /dev/nvme0n1p1 

sudo parted /dev/nvme0n2 --script mklabel gpt mkpart xfspart xfs 0% 100%
sleep 3
sudo mkfs.xfs /dev/nvme0n2p1 -f
sleep 3
sudo partprobe /dev/nvme0n2p1


sudo mdadm --create /dev/md127 --force --level=0 --raid-devices=2 \
      /dev/nvme0n3 \
      /dev/nvme0n4 
sudo mkfs.xfs /dev/md127 -f
sleep 3
sudo partprobe /dev/md127


lsblk -o NAME,HCTL,SIZE,MOUNTPOINT

sudo mkdir /mnt/cache1
sudo mkdir /mnt/temp
sudo mkdir /mnt/cache2


#sudo blkid

