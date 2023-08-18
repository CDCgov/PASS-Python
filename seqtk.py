import time
import os   
import subprocess
import shutil
from datetime import datetime
import tasklogger
import globals
from pipeline_paths import PipelinePaths

###############################################
#   seqtk
#   reads /cache1/{sra}
#       {sra}.Polio.fq
#   creates /cache2/{sra}
#       {sra}.Polio.fasta
###############################################
def process(sra: str):

    print("seqtk.process...")

    tic: float = time.perf_counter()

    paths = PipelinePaths(sra)

    tasklogger.logmetric("seqtk", sra, "ReadHits", "true")

    command = f"seqtk seq -a {paths.polio_fq_file} > {paths.polio_fasta_file}"
    completedProcess = subprocess.run(command, shell=True)

    fastaBytes = float(os.path.getsize(paths.polio_fasta_file))
    
    command2=f"echo $(grep -c '^>' {paths.polio_fasta_file})"
    completedProcess = subprocess.run(command2, shell=True)
    hitCount = subprocess.getoutput(command2)

    toc: float = time.perf_counter()

    tasklogger.logtask_with_command("seqtk",sra,fastaBytes,tic,toc,command)
    tasklogger.logmetric("seqtk",sra,"ReadHitsCount",hitCount)

