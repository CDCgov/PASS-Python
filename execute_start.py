import subprocess
import execute
import globals


globals.samples = 1

completedProcess = subprocess.run("lsblk -o NAME,HCTL,SIZE,MOUNTPOINT", shell=True, capture_output=True)

if "nvme0n1" in completedProcess.stdout.decode():
   completedProcess = subprocess.run(f"sudo mount /dev/nvme0n1p1 {globals.cache1Root}  --verbose", shell=True)
   completedProcess = subprocess.run(f"sudo mount /dev/nvme0n2p1 {globals.tempRoot}    --verbose", shell=True)
   completedProcess = subprocess.run(f"sudo mount /dev/md127     {globals.cache2Root}  --verbose", shell=True)
else:
   completedProcess = subprocess.run(f"sudo mount /dev/sdb1 {globals.cache1Root}  --verbose", shell=True)
   completedProcess = subprocess.run(f"sudo mount /dev/sdc1 {globals.tempRoot}    --verbose", shell=True)
   completedProcess = subprocess.run(f"sudo mount /dev/sdd1 {globals.cache2Root}  --verbose", shell=True)

execute.process(globals.samples)