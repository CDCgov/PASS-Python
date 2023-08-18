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
#       ???sra}.Polio.fq
#   creates /cache2/{sra}
#       ???{sra}.Polio.fasta
###############################################
def process(sra: str):

    print("seqtk.process...")

    tic: float = time.perf_counter()

    paths = PipelinePaths(sra)


#     mkdir "SPAdes_${SAMP}"
#     spades.py -t $NSLOTS -s "$SAMP".Polio.fq -o SPAdes_"$SAMP"  - creates dir: SPAdes_ERR3551042
#     cd SPAdes*
# OR USE
# spades.py -t 8 -s /cache1/ERR3551042/ERR3551042.Polio.fq -o /cache2/ERR3551042/Spades
#     if [ -s contigs.fasta ]; then
#         echo "Contigs Assembled for ${SAMP}"
#         mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","SPAdesContigs":true}},{upsert: true})'
#         export BLASTDB=/blast/db
#         blastn -task blastn -db nt -query contigs.fasta -evalue 1e-10 -num_threads $NSLOTS -num_alignments 1 -max_hsps 1 -outfmt '6 qseqid pident length qlen slen mismatch gapopen qstart qend sstart send evalue bitscore sgi sacc staxids sblastnames stitle' -out "$SAMP".Blast-NT.out
#         sed -i '1s/^/qseqid\tpident\tlength\tqlen\tslen\tmismatch\tgapopen\tqstart\tqend\tsstart\tsend\tevalue\tbitscore\tsgi\tsacc\tstaxids\tsblastnames\tstitle\n/' "$SAMP".Blast-NT.out
#         $PIPE_DIR/TSVingest.sh "$SAMP".Blast-NT.out
#         mongoimport --host="${MONGOHOST}" --username="${MONGOUSER}" --password="${MONGOPASS}" --authenticationDatabase="admin" --db=PASS --type=tsv --headerline --collection=ContigNRAlign --stopOnError "$SAMP".Blast-NT.out

# ### Blastn contigs to Polio annotated db to find polio reegion hits ###
#         blastn  -db $INDEX/PolioAnnoBlast/PolioAnno -query contigs.fasta -num_threads $NSLOTS -num_alignments 1 -outfmt "6 qseqid sseqid pident qlen length mismatch gapopen qstart qend sstart send evalue bitscore qseq sseq" >> $SAMP.contig.reads.out
#         if [ -s $SAMP.contig.reads.out ]; then
#             echo "Have contig hits for ${SAMP}"
#             $INDEX/addSabinLocation.pl $SAMP.contig.reads.out > $SAMP.contig.anno.out
#             mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ContigRegionHits":true}},{upsert: true})'
#             $PIPE_DIR/TSVingest.sh "$SAMP".contig.anno.out
#             mongoimport --host="${MONGOHOST}" --username="${MONGOUSER}" --password="${MONGOPASS}" --authenticationDatabase="admin" --db=PASS --type=tsv --headerline --collection=ContigPolAlign --stopOnError "$SAMP".contig.anno.out
#         else
#             echo "${SAMP} Contig Polio Region is Empty"
#             mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({{"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ContigRegionHits":false}},{upsert: true})'
#         fi
# ##############################
# #### Updating regions for Contig hit reads BLAST against Poliovirus annotations
#         mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.ContigPolAlign.distinct("sseqid", {"Run":"'"${SAMP}"'"})' > distContigReg.txt
#         grep -Eo '\"[0-9]+[A-Z]+|\"[A-Z]+[0-9]+' distContigReg.txt | tr -d '"' > ContigRegions.txt
#         CONTREG_LIST=$(./RegionHits_parse.py ContigRegions.txt | tr -d "'")
#         echo ${CONTREG_LIST}
#         mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.update({"Run":"'${SAMP}'"},{$addToSet:{"ContigRegionHits": {$each:'"${CONTREG_LIST}"'}}},{upsert: true})'
#     else
#         echo "${SAMP} ContigPolioAnno BLAST FILE EMPTY"
#         mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","SPAdesContigs":false}},{upsert: true})'
#     fi
# #######################

    # result = subprocess.getoutput( f"du --bytes {fastaFile}")
    # fastaBytes = result.split()[0]

    toc: float = time.perf_counter()

    tasklogger.logtask("spades",sra,bytes1,tic,toc)

