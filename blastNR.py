import os   
import subprocess
import shutil
from datetime import datetime
import tasklogger
import globals

###############################################
#   BLAST NR
#   reads 
#       /cache1/{sra}/{sra}.Polio.fq
#       /cache2/{sra}/{sra}.Polio.fasta
#   creates /cache1/{sra}
#       {sra}.NR.out
###############################################

def process(sra: str):

    tic: float = time.perf_counter()

    root = os.path.abspath(os.getcwd()) 

    fqFile =    f"/cache1/{sra}/{sra}.Polio.fq"
    fastaFile = f"/cache2/{sra}/{sra}.Polio.fasta"   
    blastNRoutFile = f"/cache1/{sra}/{sra}.NR.out"       #new

    bytes = 0

    if globals.file_size_gt_0(fqFile) == True:

        tasklogger.logmetric("blastNR", sra, "ReadHits", "Yes")

        result = subprocess.getoutput( f"grep -c '^>' {fastaFile}")
        readcount = result.split()[0]   

        tasklogger.logmetric("blastNR", sra, "ReadHitsCount",f"{readcount}")

        if readcount < 2000 :
            #!!!! NEED BLAST FILES !!!!; Very large...
            export BLASTDB=/blast/db
            command = f"blastn -task blastn -db nt -query {fastaFile} -num_threads {globals.threads} -num_alignments 1 -outfmt '6 qseqid sseqid pident qlen length mismatch gapopen qstart qend sstart send evalue bitscore qseq sseq' >> {blastNRoutFile}"
            command = "sed -i '1s/^/seqid\tsseqid\tpident\tqlen\tlength\tmismatch\tgapopen\tqstart\tqend\tsstart\tsend\tevalue\tbitscore\tqseq\tsseq\n/' {blastNRoutFile}"

            if globals.file_size_gt_0(blastNRoutFile) == True:
                tasklogger.logmetric("blastNR", sra, "ReadNRHits","yes")
            else
                tasklogger.logmetric("blastNR", sra, "ReadNRHits","no")
    
        else
           tasklogger.logmetric("blastNR", sra, "ReadNRHits","NA")



    result = subprocess.getoutput( f"du --bytes {blastNRoutFile}")
    bytes = result.split()[0]

    toc: float = time.perf_counter()

    tasklogger.logtask("blastNR",sra,bytes,tic,toc)

