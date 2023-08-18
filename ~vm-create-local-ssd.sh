#Create VM
# https://gcloud-compute.com/instances.html
# https://cloud.google.com/compute/docs/images
# https://cloud.google.com/compute/docs/images/os-details
# https://cloud.google.com/compute/docs/images/os-details#networking

 # n2-highcpu-2 #n2-highcpu-16 #Worked: n2-highcpu-8, n2-highcpu-8, n2-highcpu-4 c2d-highcpu-2
INSTANCE_TYPE=n2d-highcpu-4
DISK_TYPE=local-ssd 
NAME="sra--$INSTANCE_TYPE--$DISK_TYPE"
# us-east1-b
ZONE=asia-south1-c
gcloud compute instances create $NAME \
      --project=elasticblast-377213 \
      --zone=$ZONE \
      --machine-type=$INSTANCE_TYPE  \
      --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default  \
      --maintenance-policy=MIGRATE  \
      --provisioning-model=STANDARD  \
      --service-account=30811739638-compute@developer.gserviceaccount.com  \
      --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/cloud-platform   \
      --create-disk=auto-delete=yes,boot=yes,device-name=os,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230411,mode=rw,size=20,type=projects/elasticblast-377213/zones/$ZONE/diskTypes/pd-balanced   \
      --local-ssd=size=375,interface=NVME  \
      --local-ssd=size=375,interface=NVME  \
      --local-ssd=size=375,interface=NVME  \
      --local-ssd=size=375,interface=NVME  \
      --no-shielded-secure-boot  \
      --shielded-vtpm  \
      --shielded-integrity-monitoring  \
      --labels=goog-ec-src=vm_add-gcloud  \
      --reservation-affinity=any \
      --threads-per-core=2 \
      --metadata=startup-script="cd /home\nsudo apt-get update\nsudo apt-get -y install git\ngit init\ngit config --local user.name PASS\ngit config --local user.email pass@example.com\ngit clone https://github.com/jlongo62/pass-python pass\ncd pass\nsudo bash ./1-bootstrap.sh"

echo "sleep 60..."
sleep 60

# Install Agent
CMD="\"projects/elasticblast-377213/zones/$ZONE/instances/$NAME\",\"[{\"\"type\"\":\"\"ops-agent\"\"}]\""

:> agents_to_install.csv && \
echo $CMD >> agents_to_install.csv && \
curl -sSO https://dl.google.com/cloudagents/mass-provision-google-cloud-ops-agents.py && \
python3 mass-provision-google-cloud-ops-agents.py --file agents_to_install.csv
      
