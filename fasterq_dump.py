
###############################################
#   decompress /cache1/$ID/$ID.sra
#   to /cache2/$ID/$ID.fastq
###############################################

import globals
import time
import os   
import subprocess
import shutil
from datetime import datetime
import tasklogger
import mongologger
from pipeline_paths import PipelinePaths

def dump(sra: str):

   tic: float = time.perf_counter()

   print("fasterq_dump.process...")

   paths = PipelinePaths(sra)

   root = f"{globals.root}/sratoolkit.3.0.5-ubuntu64/bin"

   if  os.path.exists(paths.cache2_dir) is True:
      shutil.rmtree(paths.cache2_dir)
   os.mkdir(paths.cache2_dir)

   if  os.path.exists(paths.temp_dir) is True:
      shutil.rmtree(paths.temp_dir)

   command = f"{root}/fasterq-dump  {paths.cache1_dir} --outdir {paths.cache2_dir} --temp {paths.temp_dir} -e {globals.threads}" # --concatenate-reads --include-technical" 
   command = f"{root}/fasterq-dump  {paths.cache1_dir} --outdir {paths.cache2_dir} --temp {paths.temp_dir} -e {globals.threads} --split-files" # --concatenate-reads --include-technical" 
   completedProcess = subprocess.run(command, shell=True)

   bytes = float(0)
   files = os.listdir(paths.cache2_dir)
   mergedFile = f"{paths.cache2_dir}/{sra}.fastq"
   
   for file in files:
      bytes = bytes + os.path.getsize(f"{paths.cache2_dir}/{file}")

      with open(f"{paths.cache2_dir}/{file}", 'r') as f:
         data = f.read()

      # Open the second file in append mode
      with open(mergedFile, 'a') as f:
         # Append the contents of the first file to the second file
         f.write(data)

   if completedProcess.returncode != 0:
      print(f"Link Error:{sra}")  

   #bytes = float(os.path.getsize(paths.fastq_file))

   toc = float(time.perf_counter())

   tasklogger.logtask_with_command("fasterq-dump",sra,bytes,tic,toc,command)
