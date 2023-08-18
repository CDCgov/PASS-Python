
###############################################
#   creates /cache1/{sra}/{sra}.sra
###############################################

import globals
import time
import os   
import subprocess
import shutil
from datetime import datetime
import tasklogger
from pipeline_paths import PipelinePaths

def process(sra: str):

   tic: float = time.perf_counter()

   print("prefetch.process...")

   paths = PipelinePaths(sra)

   root = f"{globals.root}/sratoolkit.3.0.1-ubuntu64/bin"

   if  os.path.exists(paths.cache1_dir) is True:
      shutil.rmtree(paths.cache1_dir)
   os.mkdir(paths.cache1_dir)


   command = f"{root}/prefetch {sra} --output-file {paths.sra_file} --location GCP  --verbose --force ALL  --max-size 500000000" 

   completedProcess = subprocess.run(command, shell=True)

   result = subprocess.getoutput( f"du --bytes {paths.cache1_dir}")
   bytes = result.split()[0]

   toc: float = time.perf_counter()

   if completedProcess.returncode != 0:
      print(f"prefetch Error:{sra}")  
      tasklogger.logtask("prefetch",sra,"ERROR",tic,toc)
      return

   tasklogger.logtask("prefetch",sra,bytes,tic,toc)


