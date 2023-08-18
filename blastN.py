import time
import os   
import subprocess
import shutil
from datetime import datetime
import tasklogger
import mongologger
import globals
from pipeline_paths import PipelinePaths
import json
import bson
###############################################
#   BLAST N
#   reads 
#       /cache1/{sra}/{sra}.Polio.fq
#       /cache2/{sra}/{sra}.Polio.fasta
#   creates /cache1/{sra}
#       {sra}.N.out
#       {sra}.anno.out
###############################################
def process(sra: str):

    print("blastN.process...")

    tic: float = time.perf_counter()

    paths = PipelinePaths(sra)

    blastDBPath     = f"{globals.PASS_Anno}/PolioAnnoBlast/PolioAnno"
    distRegPath = f"{globals.cache1Root}/{sra}/distReg.txt"
    regionsPath =  f"{globals.cache2Root}/{sra}/regions.txt"

    if  os.path.exists(paths.blast_n_out_file) is True:
        os.remove(paths.blast_n_out_file)
    if  os.path.exists(paths.anno_out_file) is True:
        os.remove(paths.anno_out_file)

    if  os.path.exists(distRegPath) is True:
        os.remove(distRegPath)
    if  os.path.exists(regionsPath) is True:
        os.remove(regionsPath)    
    
    if globals.file_size_gt_0(paths.polio_fq_file) == False:

        tasklogger.logmetric("blastN", sra, "ReadHitsCount", 0)    

    else:

        tasklogger.logmetric("blastN", sra, "ReadHits", "Yes")

        result = subprocess.getoutput( f"grep -c '^>' {paths.polio_fasta_file}")
        readcount = int(result.split()[0])   
        tasklogger.logmetric("blastN", sra, "ReadHitsCount", readcount)

        if readcount > 40000 :
            tasklogger.logmetric("blastN", sra, "ReadBlastHits","false")
        
        else:
            command = f'''blastn  -db {blastDBPath} \
                            -query {paths.polio_fasta_file} \
                            -num_threads {globals.threads} \
                            -num_alignments 1 -max_hsps 1 \
                            -outfmt "6 qseqid sseqid pident qlen length mismatch gapopen qstart qend sstart send evalue bitscore qseq sseq" >> {paths.blast_n_out_file}'''

            completedProcess = subprocess.run(command, shell=True)
        
            if globals.file_size_gt_0(paths.blast_n_out_file) == False:
                tasklogger.logmetric("blastN", sra, "ReadBlastHits","false")       

            else:

                tasklogger.logmetric("blastN", sra, "ReadBlastHits","true")

                command = f"{globals.PASS_Anno}/addSabinLocation.pl {paths.blast_n_out_file} > {paths.anno_out_file}"
                completedProcess = subprocess.run(command, shell=True)
                   
                command = f"{globals.root}/TSVingest.sh  {paths.anno_out_file}"
                completedProcess = subprocess.run(command, shell=True)

                #>>> mongoimport --host="${MONGOHOST}" --username="${MONGOUSER}" --password="${MONGOPASS}" --authenticationDatabase="admin" --db=PASS 
                #>>>    --type=tsv --headerline --collection=ReadPolAlign 
                #>>>    --stopOnError "$SAMP".anno.out
                mongologger.importFile("blastN",sra,paths.anno_out_file, "ReadPolAlign", "tsv")

                #>>> mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS \
                #>>>    --eval 'db.ReadPolAlign.distinct("sseqid", {"Run":"'"${SAMP}"'"})' > distReg.txt
                lines = mongologger.queryDistinct("blastN",sra,"ReadPolAlign","sseqid", { "Run": sra } )
                with open(distRegPath, 'w') as file:
                    for line in lines:
                        file.write(f'"{line}"' + '\n')

                command = f'grep -Eo \'\\"[0-9]+[A-Z]+|\\"[A-Z]+[0-9]+\' {distRegPath} | tr -d \'"\' > {regionsPath}'
                completedProcess = subprocess.run(command, shell=True)

                #Lines 102 - 114  do this:
                #>>>REG_LIST=$(./RegionHits_parse.py regions.txt | tr -d "'")
                #>>>	echo ${REG_LIST}	
                # regionsPath becomes list of strings:
                # "xxx" 
                # "yyy"

                #>>>mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS 
                # --eval 'db.data.update({"Run":"'${SAMP}'"},{$addToSet:{"RegionHits": {$each:'"${REG_LIST}"'}}},{upsert: true})'

                with open(regionsPath, "r") as f:
                    content = f.read()
                    lines = content.splitlines()

                distinct_list = list(dict.fromkeys(lines))

                set = { 
                    "$set": 
                    { "RegionHits": 
                        distinct_list
                    }
                }
    
                mongologger.update_one_by_set("blastN", sra, set)

                print("")
                        
    bytes1 = 0
    bytes2 = 0
    if globals.file_size_gt_0(paths.blast_n_out_file):
        bytes1 = os.path.getsize(paths.blast_n_out_file)
    if globals.file_size_gt_0(paths.anno_out_file):
        bytes2 = os.path.getsize(paths.anno_out_file)

    toc: float = time.perf_counter()

    tasklogger.logtask("blastN", sra, bytes1+bytes2, tic, toc)

