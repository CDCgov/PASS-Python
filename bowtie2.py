###############################################
#   bowtie2
#   Input: /cache2/{sra}/{sra}.fastq
#   creates /cache1/{sra}
#       $ID.Polio.fq
#       $ID.NoPolio.fq
#       $ID.Polio.sam
###############################################


import time
import os   
import subprocess
import shutil
from datetime import datetime
import tasklogger
import globals
from pipeline_paths import PipelinePaths

def process(sra: str):

   print("bowtie2.process...")

   tic: float = time.perf_counter()

   paths = PipelinePaths(sra)

   if  os.path.exists(paths.nopolio_fq_file) is True:
      os.remove(paths.nopolio_fq_file)
   if  os.path.exists(paths.polio_fq_file) is True:
       os.remove(paths.polio_fq_file)
   if  os.path.exists(paths.polio_sam_file) is True:
       os.remove(paths.polio_sam_file)

   # --very-fast-local speeds up process...not benchmarked
   command = f'''bowtie2 -p {globals.threads}  --sensitive-local \
      -N 1 -t --quiet \
      -x    {globals.PASS_Anno}/PolioAnnoKmer/PolioAnno_kmer \
      -U    {paths.fastq_file}  \
      --un  {paths.nopolio_fq_file} \
      --al  {paths.polio_fq_file} \
      -S    {paths.polio_sam_file}'''

#   bowtie2 [options]* -x <bt2-idx> {-1 <m1> -2 <m2> | -U <r> | --interleaved <i> | -b <bam>} [-S <sam>]

#   <bt2-idx>  Index filename prefix (minus trailing .X.bt2).
#              NOTE: Bowtie 1 and Bowtie 2 indexes are not compatible.
#   <m1>       Files with #1 mates, paired with files in <m2>.
#              Could be gzip'ed (extension: .gz) or bzip2'ed (extension: .bz2).
#   <m2>       Files with #2 mates, paired with files in <m1>.
#              Could be gzip'ed (extension: .gz) or bzip2'ed (extension: .bz2).
#   <r>        Files with unpaired reads.
#              Could be gzip'ed (extension: .gz) or bzip2'ed (extension: .bz2).

   # command = f'''bowtie2 -p {globals.threads}  --sensitive-local \
   #    -N 1 -t --quiet \
   #    -x    {globals.PASS_Anno}/PolioAnnoKmer/PolioAnno_kmer \
   #    --un  {paths.nopolio_fq_file} \
   #    --al  {paths.polio_fq_file} \
   #    -S    {paths.polio_sam_file}'''

   # files = os.listdir(paths.cache2_dir)
   # for file in files:
   #    if file == f"{sra}.fastq":
   #       command = command + f"  -U {paths.cache2_dir}/{sra}.fastq"

   #    if file == f"{sra}_1.fastq":
   #       command = command + f"  -1 {paths.cache2_dir}/{sra}_1.fastq"

   #    if file == f"{sra}_2.fastq":
   #       command = command + f"  -2 {paths.cache2_dir}/{sra}_2.fastq"


   completedProcess = subprocess.run(command, shell=True)

   bowtieBytes = float(os.path.getsize(paths.nopolio_fq_file))
   bowtieBytes = bowtieBytes + float(os.path.getsize(paths.polio_fq_file))
   bowtieBytes = bowtieBytes + float(os.path.getsize(paths.polio_sam_file))

   toc: float = time.perf_counter()

   tasklogger.logtask_with_command("bowtie2",sra,bowtieBytes,tic,toc,command)


   if globals.file_size_gt_0(paths.polio_fq_file) == False:
      tasklogger.logmetric("bowtie2",sra,"ReadHits","false")
      tasklogger.logmetric("bowtie2",sra,"ReadHitsCount","0")
      tasklogger.logmetric("bowtie2",sra,"ReadBlastHits","false")
      tasklogger.logmetric("bowtie2",sra,"ReadNRHits","false")
      tasklogger.logmetric("bowtie2",sra,"SPAdesContigs","false")
      return False
   
   else: 
      tasklogger.logmetric("bowtie2",sra,"ReadHits","true")
      return True
       


