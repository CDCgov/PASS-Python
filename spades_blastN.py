import time
import os   
import subprocess
import shutil
from datetime import datetime
import tasklogger
import mongologger
import globals
from pipeline_paths import PipelinePaths

###############################################
#   seqtk
#   reads /cache1/{sra}
#       ???sra}.Polio.fq
#   creates /cache2/{sra}
#       ???{sra}.Polio.fasta
###############################################
def process(sra: str):

    print("spades_blastN.process...")

    tic: float = time.perf_counter()

    paths = PipelinePaths(sra)

    blastDBPath     = f"{globals.PASS_Anno}/PolioAnnoBlast/PolioAnno"

    distRegPath = f"{globals.cache1Root}/{sra}/distContigReg.txt"
    regionsPath =  f"{globals.cache2Root}/{sra}/ContigRegions.txt"

    if  os.path.exists(paths.spades_contig_n_out_file) == True:
        os.remove(paths.spades_contig_n_out_file)
    if  os.path.exists(paths.spades_contig_anno_n_out_file) == True:
        os.remove(paths.spades_contig_anno_n_out_file)

    if  os.path.exists(distRegPath) is True:
        os.remove(distRegPath)
    if  os.path.exists(regionsPath) is True:
        os.remove(regionsPath)    
    
    command = f'''blastn  -db {blastDBPath} \
                    -query {paths.spades_contig_fasta_file} \
                    -num_threads {globals.threads} \
                    -num_alignments 1 \
                    -outfmt '6 qseqid sseqid pident qlen length mismatch gapopen qstart qend sstart send evalue bitscore qseq sseq' >> {paths.spades_contig_n_out_file}'''

    completedProcess = subprocess.run(command, shell=True)

    if globals.file_size_gt_0(paths.spades_contig_n_out_file) == False:

        tasklogger.logmetric("spades_blastN", sra, "ContigHits","false")

    else:

        tasklogger.logmetric("spades_blastN", sra, "ContigHits","true")

        command = f"{globals.PASS_Anno}/addSabinLocation.pl {paths.spades_contig_n_out_file} > {paths.spades_contig_anno_n_out_file}"
        completedProcess = subprocess.run(command, shell=True)
            
        command = f"{globals.root}/TSVingest.sh  {paths.spades_contig_anno_n_out_file}"
        completedProcess = subprocess.run(command, shell=True)

        #$PIPE_DIR/TSVingest.sh "$SAMP".contig.anno.out
        #mongoimport --host="${MONGOHOST}" --username="${MONGOUSER}" --password="${MONGOPASS}" --authenticationDatabase="admin" --db=PASS 
        #   --type=tsv --headerline --collection=ContigPolAlign --stopOnError "$SAMP".contig.anno.out
        mongologger.importFile("spades_blastN",sra,paths.spades_contig_anno_n_out_file, "ContigPolAlign", "tsv")

        #>>> mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS -
        #>>>   -eval 'db.ContigPolAlign.distinct("sseqid", {"Run":"'"${SAMP}"'"})' > distContigReg.txt
        lines = mongologger.queryDistinct("spades_blastN",sra,"ContigPolAlign","sseqid", { "Run": sra } )
        with open(distRegPath, 'w') as file:
            for line in lines:
                file.write(f'"{line}"' + '\n')

    # grep -Eo '\"[0-9]+[A-Z]+|\"[A-Z]+[0-9]+' distContigReg.txt | tr -d '"' > ContigRegions.txt
        command = f'grep -Eo \'\\"[0-9]+[A-Z]+|\\"[A-Z]+[0-9]+\' {distRegPath} | tr -d \'"\' > {regionsPath}'
        completedProcess = subprocess.run(command, shell=True)

    # CONTREG_LIST=$(./RegionHits_parse.py ContigRegions.txt | tr -d "'")
    # echo ${CONTREG_LIST}
    # mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS 
    #   --eval 'db.data.update({"Run":"'${SAMP}'"},{$addToSet:{"ContigRegionHits": {$each:'"${CONTREG_LIST}"'}}},{upsert: true})'
        with open(regionsPath, "r") as f:
            content = f.read()
            lines = content.splitlines()

        distinct_list = list(dict.fromkeys(lines))

        set = { 
            "$set": 
            { "ContigRegionHits": 
                distinct_list
            }
        }

        mongologger.update_one_by_set("spades_blastN", sra, set)
     

    if os.path.isfile(paths.spades_contig_n_out_file):
        bytes1 = os.path.getsize(paths.spades_contig_n_out_file)

    toc: float = time.perf_counter()

    tasklogger.logtask("spades_blastN",sra,bytes1,tic,toc)

