import time
import os   
import subprocess
import shutil
from datetime import datetime
import tasklogger
import globals
from pipeline_paths import PipelinePaths
from pathlib import Path


###############################################
#   seqtk
#   reads 
#        /cache1/{sra}/{sra}.Polio.fq
#
#   creates /cache2/{sra}
#       /cache2/{sra}/Spades/**
#       /cache2/{sra}/Spades/contigs.fasta
###############################################
def process(sra: str):

   print("spades.process...")

   tic: float = time.perf_counter()

   paths = PipelinePaths(sra)

   if (os.path.exists(paths.spades_dir)):
         shutil.rmtree(paths.spades_dir) 

   # spades.py -t 8 -s /cache1/ERR3551042/ERR3551042.Polio.fq -o /cache2/ERR3551042/
   command = f"spades.py -t {globals.threads} -s {paths.polio_fq_file} -o {paths.spades_dir}" # creates dir: SPAdes_ERR3551042"
   completedProcess = subprocess.run(command, shell=True)

   result = subprocess.getoutput( f"du --summarize --bytes {paths.spades_dir}")
   bytes1 = result.split()[0]

   toc: float = time.perf_counter()

   tasklogger.logtask("spades", sra, bytes1, tic, toc)
   

   if globals.file_size_gt_0(paths.spades_contig_fasta_file) == True:
      tasklogger.logmetric("spades",sra,"SPAdesContigs","true")
      return True
   
   else: 
      tasklogger.logmetric("spades",sra,"SPAdesContigs","false")
      return False



