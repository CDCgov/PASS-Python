git config --local  user.name "PASS"
git config --local  user.email pass@example.com

sudo bash ./2.1-software.sh
sudo bash ./2.2-odbc.sh
sudo bash ./4-configure-sratoolkit.sh
sudo bash ./5-configure-bowtie2.sh
sudo bash ./6-configure-seqtk.sh
sudo bash ./7-configure-spades.sh
sudo bash ./8-configure-blast.sh

#Command Depends on Disk Type
#sudo bash ./9.1-prepare_disks-nvme.sh
sudo bash 9.2-prepare_disks-pd.sh
