#Create VM
#https://gcloud-compute.com/instances.html

INSTANCE_TYPE=n2d-highcpu-4
DISK_TYPE=pd-standard   #pd-balanced,pd-ssd
NAME="sra--$INSTANCE_TYPE--$DISK_TYPE"
ZONE=asia-south1-c # us-east1-b


gcloud compute disks create $NAME-cache  --project=elasticblast-377213 --type=$DISK_TYPE --size=375GB --zone=$ZONE
gcloud compute disks create $NAME-temp   --project=elasticblast-377213 --type=$DISK_TYPE --size=750GB --zone=$ZONE
gcloud compute disks create $NAME-output --project=elasticblast-377213 --type=$DISK_TYPE --size=375GB --zone=$ZONE

gcloud compute instances create $NAME \
      --project=elasticblast-377213 \
      --zone=$ZONE  \
      --machine-type=$INSTANCE_TYPE  \
      --network-interface=network-tier=PREMIUM,subnet=default  \
      --maintenance-policy=MIGRATE  \
      --provisioning-model=STANDARD  \
      --service-account=30811739638-compute@developer.gserviceaccount.com  \
      --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/cloud-platform   \
      --create-disk=auto-delete=yes,boot=yes,device-name=os,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230411,mode=rw,size=20,type=projects/elasticblast-377213/zones/$ZONE/diskTypes/$DISK_TYPE   \
      --disk=auto-delete=yes,boot=no,device-name=cache,mode=rw,name=$NAME-cache  \
      --disk=auto-delete=yes,boot=no,device-name=temp,mode=rw,name=$NAME-temp  \
      --disk=auto-delete=yes,boot=no,device-name=output,mode=rw,name=$NAME-output  \
      --no-shielded-secure-boot  \
      --shielded-vtpm  \
      --shielded-integrity-monitoring  \
      --labels=ec-src=vm_add-gcloud  \
      --reservation-affinity=any \
      --threads-per-core=2 \
      --metadata=startup-script='#! /bin/bash

sudo apt-get update
sudo apt-get -y install git

sudo mkdir /git
sudo chmod +777 /git    
cd /git 
git init
git config --local  user.name "PASS"
git config --local  user.email pass@example.com
git clone https://github.com/jlongo62/pass-python pass
cd pass

sudo bash ./1-bootstrap.sh
sudo bash ./9.2-prepare_disks-pd.sh

       EOF'
 
echo "sleep 60..."
sleep 60

# Install Agent
CMD="\"projects/elasticblast-377213/zones/$ZONE/instances/$NAME\",\"[{\"\"type\"\":\"\"ops-agent\"\"}]\""

:> agents_to_install.csv && \
echo $CMD >> agents_to_install.csv && \
curl -sSO https://dl.google.com/cloudagents/mass-provision-google-cloud-ops-agents.py && \
python3 mass-provision-google-cloud-ops-agents.py --file agents_to_install.csv
      
