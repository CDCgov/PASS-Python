import prefetch_http
import fasterq_dump
import os   
import shutil
import subprocess
import time
import datetime

import bowtie2
import seqtk
import blastN
import spades_
import spades_blastN
import shutil
import prefetch
import tasklogger

import globals
import mongologger
#####################################################################
#todo:  Add Run #, machine details to output, flag to log text or DB
#####################################################################
def process(id: int):

   completedProcess = subprocess.run(f"sudo chmod +777 {globals.cache1Root}", shell=True)
   completedProcess = subprocess.run(f"sudo chmod +777 {globals.cache2Root}", shell=True)
   completedProcess = subprocess.run(f"sudo chmod +777 {globals.tempRoot}", shell=True)
   completedProcess = subprocess.run(f"sudo chmod +777 {globals.root}/TSVingest.sh", shell=True)

   mongologger.clearCollection("execute.process","data")
   mongologger.clearCollection("execute.process","ReadPolAlign")
   mongologger.clearCollection("execute.process","ContigPolAlign")

   if  os.path.exists(f"timings.log") is True:
      os.remove(f"timings.log")
   if  os.path.exists(f"metric.log") is True:
      os.remove(f"metric.log")

   shutil.copytree(f"{globals.root}/PASS_Anno", globals.PASS_Anno, dirs_exist_ok=True) 
   completedProcess = subprocess.run(f"sudo chmod +777 {globals.PASS_Anno}/addSabinLocation.pl", shell=True)
  
   with open(f"sralist-{id}.txt", "r") as file:
      sz = file.read()

   a = sz.split("\n")

   cnt = 0
   for sra in a:

      tic: float = time.perf_counter()

      tasklogger.logmetric("prefetch-http",sra,"RunElapsedTime",None)
      tasklogger.logmetric("prefetch-http",sra,"RunStartDate", datetime.datetime.utcnow())
      tasklogger.logmetric("prefetch-http",sra,"RunEndDate",None)

      #prefetch.process(sra)
      prefetch_http.prefetch(sra)
      fasterq_dump.dump(sra)
      if bowtie2.process(sra):
         seqtk.process(sra)
         blastN.process(sra)

         if spades_.process(sra):
            spades_blastN.process(sra)

      if  os.path.exists(f"{globals.cache1Root}/{sra}") is True:
         shutil.rmtree(f"{globals.cache1Root}/{sra}")

      if  os.path.exists(f"{globals.tempRoot}/{sra}") is True:
         shutil.rmtree(f"{globals.tempRoot}/{sra}")

      if  os.path.exists(f"{globals.cache2Root}/{sra}") is True:
         shutil.rmtree(f"{globals.cache2Root}/{sra}")

      toc = float(time.perf_counter())

      tasklogger.logmetric("execute", sra, "RunElapsedTime",f"{(toc - tic):.3f}")
      tasklogger.logmetric("execute", sra, "RunEndDate",datetime.datetime.utcnow() )

      #break


