#!/bin/bash
source /etc/profile
source /scicomp/scratch/PASS/config.sh
source /etc/profile.d/modules.sh
chmod +rwx /scicomp/home-pure/ncbs-c/.lmod.d/.cache/spiderT.x86_64_Linux.lua

#HPC file provided by Katie via Email 6/14/23 3:07PM
#############################################################
# Setting cluster                                           
#############################################################
#$ -pe smp 4-6 # num cores requested           
##$ -m e -M qdh2@cdc.gov #email start, abort and end of run
#############################################################
  
##### WORKING FORMAT #####################
# 1) function definitions                #
# 2) variable declaration & control flow #
##########################################

# Will append current log to master log for given <upload date>_SRAList.txt
append_tracking_logs() {

    # Append run STDOUT/STDERR logs to respective master log files
    RUNDATE=$(date +'%m.%d' --date=$ISODATE)

    echo "> ${SAMP}" >> "${START_DIR}/${LOGDATE}_${RUNDATE}_mPipe.out"
    cat "${SGE_STDOUT_PATH}" >> "${START_DIR}/${LOGDATE}_${RUNDATE}_mPipe.out"
    # TODO Replace all rm with find -name -delete (generally safer)
    rm "${SGE_STDOUT_PATH}"

    echo "> ${SAMP}" >> "${START_DIR}/${LOGDATE}_${RUNDATE}_mPipe.err"
    cat "${SGE_STDERR_PATH}" >> "${START_DIR}/${LOGDATE}_${RUNDATE}_mPipe.err"
    rm "${SGE_STDERR_PATH}"

    # Temp until .p* ID'd 
    ### Find more elegant/safe way to delete, or determine if reliable. 
    find ${START_DIR} -regex ".*_pipe\.p.*" -delete

    # Append sample to tracking sheet before exiting 
    # $JNAME declared during flow
    echo "$SAMP" >> "${START_DIR}/${JNAME}_tracking.txt"
    mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS \
    --eval 'db.tracking.findOneAndUpdate({"Run":'"${SAMP}"'},{$set:{"Run":'"${SAMP}"', "complete":true}},{upsert:true})'          
}

unload_modules() {
    module unload sratoolkit
    module unload mongo
    module unload bowtie2
    module unload seqtk/1.2
    module unload ncbi-blast+
    module unload SPAdes
}

fastq_transfer_fromSRA() {
	echo "Found ${SAMP}.sra and performing fastq transfer.."
    SECONDS=0
	cd "${SCRATCH_DIR}/${SAMP}"
	mkdir $SCRATCH_DIR/$SAMP/tmp
    # Utilizes scratch directory and max slots to optimize speed 
	fasterq-dump $SCRATCH_DIR/$SAMP/"${SAMP}.sra" -O $SCRATCH_DIR/$SAMP/ -t $SCRATCH_DIR/$SAMP/tmp -e $NSLOTS
        # Checks for empty string return from subshell. If empty, then retry
        if test -z "$(find $SCRATCH_DIR/$SAMP/ -maxdepth 1 -name '*.fastq' -print -quit)"; then
            echo "Running 2nd fasterq-dump.."
            fasterq-dump $SCRATCH_DIR/$SAMP/"${SAMP}.sra" -O $SCRATCH_DIR/$SAMP/ -t $SCRATCH_DIR/$SAMP/tmp -e $NSLOTS
            # Advised by NCBI to run fastq-dump for accessions that may fail with fasterq-dump
	        if test -z "$(find $SCRATCH_DIR/$SAMP/ -maxdepth 1 -name '*.fastq' -print -quit)"; then
		        echo "2nd fasterq-dump fail.. performing fastq-dump"
		        fastq-dump $SCRATCH_DIR/$SAMP/"${SAMP}.sra" -O $SCRATCH_DIR/$SAMP/
            fi
	    fi
	rm -r $SCRATCH_DIR/$SAMP/tmp
    SECONDS_STOP=$SECONDS
    TIME_ELAPSED="$(($SECONDS_STOP / 60))m$(($SECONDS_STOP % 60))s"
    echo "$TIME_ELAPSED elapsed for $SAMP"

    mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS \
    --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","SRAfastqdump_time":("'$TIME_ELAPSED'")}},{upsert: true})'
}

concatenate_fastq() {
    # Checks for non-zero string length
    if test -n "$(find $SCRATCH_DIR/$SAMP/ -maxdepth 1 -name '*.fastq' -print -quit)"; then
	    echo "Concatenating ${SAMP}.fastq..."
	    cat $SCRATCH_DIR/$SAMP/*fastq >> $SCRATCH_DIR/$SAMP/"${SAMP}_merged.fq"
	    ## recursive find . delete better?
        rm $SCRATCH_DIR/$SAMP/*fastq
        if [ -d "$SCRATCH_DIR/$SAMP/tmp" ]; then
            rm -r "$SCRATCH_DIR/$SAMP/tmp"
        fi
    else
	    echo "Cannot find ${SAMP}.fastq.. check logs and solve."
        unload_modules
	    append_tracking_logs
	    exit 1
    fi
    # Check for merged fastq. Capture filesize if exists
    if [ ! -f "${SCRATCH_DIR}/${SAMP}/${SAMP}_merged.fq" ]; then
	    echo "Could not find ${SAMP}_merged.fq .. exit 1 pipeline."
        unload_modules 
	    append_tracking_logs
	    exit 1
    else
        # Capture human readable filesize after confirming merged reads exist
        FASTQ_FILESIZE=$(ls -lh "${SCRATCH_DIR}/${SAMP}/${SAMP}_merged.fq" | awk '{print $5}')
        # Append read/fastq filesize to mongodb document for sample
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS \
    --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","SRAfastq_size":("'$FASTQ_FILESIZE'")}},{upsert: true})'
    fi
}

alignSRAseq_to_poliokmer() {
    SECONDS=0
    echo "Performing ${SAMP} alignment with Bowtie2.."
    bowtie2 -p $NSLOTS --sensitive-local -N 1 -t --quiet -x $INDEX/PolioAnnoKmer/PolioAnno_kmer -U "${SAMP}_merged.fq" --un $SAMP.NoPolio.fq --al $SAMP.Polio.fq -S $SAMP.Polio.sam

    SECONDS_STOP=$SECONDS
    TIME_ELAPSED="$(($SECONDS_STOP / 60))m$(($SECONDS_STOP % 60))s"
    echo "$TIME_ELAPSED elapsed for $SAMP"

    mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS \
    --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","bowtie2_time":("'$TIME_ELAPSED'")}},{upsert: true})'

    if [ -s $SAMP.Polio.fq ]; then
        echo "${SAMP} has potentil Polio hits"
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","SRAReleaseDate":new Date("'$ISODATE'")}},{upsert: true})'
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadHits":true}},{upsert: true})'
        seqtk seq -a $SAMP.Polio.fq > $SAMP.Polio.fasta
        READCOUNT=$(grep -c "^>" $SAMP.Polio.fasta)
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadHitsCount":'$READCOUNT'}},{upsert: true})'
        # Cleanup unused data
        #find . -name "$SCRATCH_DIR/$SAMP/$SAMP.NoPolio.fq" -delete
        #find . -name "$SCRATCH_DIR/$SAMP/$SAMP.Polio.sam" -delete
        #find . -name "$SCRATCH_DIR/$SAMP/${SAMP}.sra" -delete
    else
        echo "${SAMP} does not contain alignments for potential Polio" # remove file sra file and folder
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadHits":false}},{upsert: true})'
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadHitsCount":0}},{upsert: true})'
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadBlastHits":false}},{upsert: true})'
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadNRHits":false}},{upsert: true})'
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","SPAdesContigs":false}},{upsert: true})'
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","SRAReleaseDate":new Date("'$ISODATE'")}},{upsert: true})'
        cd "${SCRATCH_DIR}"
	    rm -r "${SCRATCH_DIR}/${SAMP}"
        
        unload_modules
        append_tracking_logs
        exit 1
    fi
}

blast_polioanno_NR() {
    # Blast potential Polio reads against curated annotation && against NR 
    # Only return 1hsp per query if readcounts > 40000. Otherwise, data can grow out of control for pos. polio hits
    if (($READCOUNT > 40000)); then
    	echo "ReadHit counts are too large to BLAST ${SAMP} against Polio Annotations"
	mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadBlastHits":false}},{upsert: true})'
    else
	blastn  -db $INDEX/PolioAnnoBlast/PolioAnno -query $SAMP.Polio.fasta -num_threads $NSLOTS -num_alignments 1 -max_hsps 1 -outfmt "6 qseqid sseqid pident qlen length mismatch gapopen qstart qend sstart send evalue bitscore qseq sseq" >> $SAMP.reads.out
    fi    

    if [ -s $SAMP.reads.out ]; then
        echo "Found read hits for ${SAMP}"
        $INDEX/addSabinLocation.pl $SAMP.reads.out > $SAMP.anno.out
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadBlastHits":true}},{upsert: true})'
         
        $PIPE_DIR/TSVingest.sh "$SAMP".anno.out
        mongoimport --host="${MONGOHOST}" --username="${MONGOUSER}" --password="${MONGOPASS}" --authenticationDatabase="admin" --db=PASS --type=tsv --headerline --collection=ReadPolAlign --stopOnError "$SAMP".anno.out
        rm $SAMP.reads.out
	
	#### Updating regions for kmer hit reads BLAST against Poliovirus annotations
	mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.ReadPolAlign.distinct("sseqid", {"Run":"'"${SAMP}"'"})' > distReg.txt
	grep -Eo '\"[0-9]+[A-Z]+|\"[A-Z]+[0-9]+' distReg.txt | tr -d '"' > regions.txt
	REG_LIST=$(./RegionHits_parse.py regions.txt | tr -d "'")
    	echo ${REG_LIST}	
	mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.update({"Run":"'${SAMP}'"},{$addToSet:{"RegionHits": {$each:'"${REG_LIST}"'}}},{upsert: true})'
    else
        echo "${SAMP} PolioAnno BLAST FILE EMPTY"
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadBlastHits":false}},{upsert: true})'
    fi
 
    #######Blast Reads to NR
    if (($READCOUNT > 3000)); then
        echo "ReadHit counts are too large to BLAST ${SAMP} against NR"
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadNRHits":false}},{upsert: true})'
    else
        echo "Will BLAST ${SAMP} hits to NR(Nucleotide)"
        export BLASTDB=/blast/db
        blastn -task blastn -db nt -query $SAMP.Polio.fasta -num_threads $NSLOTS -num_alignments 1 -outfmt "6 qseqid sseqid pident qlen length mismatch gapopen qstart qend sstart send evalue bitscore qseq sseq" >> $SAMP.NR.out
        sed -i '1s/^/seqid\tsseqid\tpident\tqlen\tlength\tmismatch\tgapopen\tqstart\tqend\tsstart\tsend\tevalue\tbitscore\tqseq\tsseq\n/' $SAMP.NR.out
        if [ -s $SAMP.NR.out ]; then
            mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadNRHits":true}},{upsert: true})'
            $PIPE_DIR/TSVingest.sh "$SAMP".NR.out
            mongoimport --host="${MONGOHOST}" --username="${MONGOUSER}" --password="${MONGOPASS}" --authenticationDatabase="admin" --db=PASS --type=tsv --headerline --collection=ReadNRAlign --stopOnError "$SAMP".NR.out
	    else
            echo "${SAMP} READ NR BLAST FILE EMPTY"
            mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadNRHits":false}},{upsert: true})'
        fi
    fi
}

spades_assembly() {
    mkdir "SPAdes_${SAMP}"
    spades.py -t $NSLOTS -s "$SAMP".Polio.fq -o SPAdes_"$SAMP"
    cd SPAdes*

    if [ -s contigs.fasta ]; then
        echo "Contigs Assembled for ${SAMP}"
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","SPAdesContigs":true}},{upsert: true})'
        export BLASTDB=/blast/db
        blastn -task blastn -db nt -query contigs.fasta -evalue 1e-10 -num_threads $NSLOTS -num_alignments 1 -max_hsps 1 -outfmt '6 qseqid pident length qlen slen mismatch gapopen qstart qend sstart send evalue bitscore sgi sacc staxids sblastnames stitle' -out "$SAMP".Blast-NT.out
        sed -i '1s/^/qseqid\tpident\tlength\tqlen\tslen\tmismatch\tgapopen\tqstart\tqend\tsstart\tsend\tevalue\tbitscore\tsgi\tsacc\tstaxids\tsblastnames\tstitle\n/' "$SAMP".Blast-NT.out
        $PIPE_DIR/TSVingest.sh "$SAMP".Blast-NT.out
        mongoimport --host="${MONGOHOST}" --username="${MONGOUSER}" --password="${MONGOPASS}" --authenticationDatabase="admin" --db=PASS --type=tsv --headerline --collection=ContigNRAlign --stopOnError "$SAMP".Blast-NT.out

### Blastn contigs to Polio annotated db to find polio reegion hits ###
        blastn  -db $INDEX/PolioAnnoBlast/PolioAnno -query contigs.fasta -num_threads $NSLOTS -num_alignments 1 -outfmt "6 qseqid sseqid pident qlen length mismatch gapopen qstart qend sstart send evalue bitscore qseq sseq" >> $SAMP.contig.reads.out
        if [ -s $SAMP.contig.reads.out ]; then
            echo "Have contig hits for ${SAMP}"
            $INDEX/addSabinLocation.pl $SAMP.contig.reads.out > $SAMP.contig.anno.out
            mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ContigRegionHits":true}},{upsert: true})'
            $PIPE_DIR/TSVingest.sh "$SAMP".contig.anno.out
            mongoimport --host="${MONGOHOST}" --username="${MONGOUSER}" --password="${MONGOPASS}" --authenticationDatabase="admin" --db=PASS --type=tsv --headerline --collection=ContigPolAlign --stopOnError "$SAMP".contig.anno.out
        else
            echo "${SAMP} Contig Polio Region is Empty"
            mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({{"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ContigRegionHits":false}},{upsert: true})'
        fi
##############################
#### Updating regions for Contig hit reads BLAST against Poliovirus annotations
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.ContigPolAlign.distinct("sseqid", {"Run":"'"${SAMP}"'"})' > distContigReg.txt
        grep -Eo '\"[0-9]+[A-Z]+|\"[A-Z]+[0-9]+' distContigReg.txt | tr -d '"' > ContigRegions.txt
        CONTREG_LIST=$(./RegionHits_parse.py ContigRegions.txt | tr -d "'")
        echo ${CONTREG_LIST}
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.update({"Run":"'${SAMP}'"},{$addToSet:{"ContigRegionHits": {$each:'"${CONTREG_LIST}"'}}},{upsert: true})'
    else
        echo "${SAMP} ContigPolioAnno BLAST FILE EMPTY"
        mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","SPAdesContigs":false}},{upsert: true})'
    fi
#######################
}

fetch_metadata() {
    # Will fetch metadata for anything with ReadHits: True
    echo "${SAMP} not empty fetching metadata"
    module load Entrez/E-utilities

	cd "${SCRATCH_DIR}/${SAMP}"
    mkdir metadata
	cd metadata
    
    #Fetch main SRA metadata in runinfo format
	efetch -db sra -id $SAMP -format runinfo > $SAMP.csv 2>$SAMP.err
	HEADER=$(head -n1 $SAMP.csv)
	METADATA=$(cat $SAMP.csv | awk -v pat="$SAMP" '$1 ~ pat')
	IFS=',' read -r -a METAfoo <<< $METADATA

	# Offset Entrez API request limit
	sleep 2
	LOCATION=$(esearch -db sra -query $SAMP | elink -target biosample | efetch -format docsum | xtract -pattern DocumentSummary -block Attribute -if Attribute@attribute_name -equals geo_loc_name -element Attribute)	
    HEAD="location"
	FINALHEADER="$HEADER,$HEAD"
	FINALMETADATA="$METADATA,$LOCATION"
	echo -e "$FINALHEADER \n $FINALMETADATA" > $SAMP.csv

	mongoimport --host="${MONGOHOST}" --username="${MONGOUSER}" --password="${MONGOPASS}" --authenticationDatabase="admin" --db=PASS -c data --type csv --file $SAMP.csv --headerline

	# Offset Entrez API request limit
	sleep 2
	BIOSAMPLE=$(efetch -db biosample -id ${METAfoo[25]} -format native | sed 's/"//g')
	echo $BIOSAMPLE > $SAMP.biosample.txt

	echo 'db.data.findOneAndUpdate({"Run":"'${METAfoo[0]}'"},{$set:{"bioSampleDetails": "'$BIOSAMPLE'"}},{upsert: true})' > $SAMP.js
	mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS < $SAMP.js
}

######################
### MAIN EXECUTION ###
######################
date
date1=$(date +"%s")

module load Entrez/E-utilities
module load sratoolkit
module load mongo
module load bowtie2
module load seqtk/1.2
module load ncbi-blast+
module load SPAdes

SRALIST=$1
SAMP=$(awk '{if(NR=='"$SGE_TASK_ID"') print $0}' $SRALIST)
#SAMP=$(cat $SRALIST)

START_DIR=$(pwd -P)
echo "Starting ${SAMP} pipeline from ${START_DIR}"

# LOGDATE follows MM.DD of sraDL_Pipe.sh execution
# ISODATE follows SRA upload date
LOGDATE=$2
ISODATE=$(echo $SRALIST | grep -aoP "[0-9]+[-][0-9]+[-][0-9]+")

# Var to use with _tracking log
JNAME=$3

HAVEIT=$(mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS --eval 'db.data.find({"Run":"'${SAMP}'"},{"SRAPrefetch_time":1}).limit(1).size()')



#### BEGIN CONTROL FLOW ####

#if [ "$HAVEIT" == 0 ]; then
#    echo "${SAMP} not found in MongoDB"
#HAVEIT=1

if [ "$HAVEIT" == 1 ]; then
    echo "${SAMP} prefetch record found in MongoDB" 
    if [ -f $SCRATCH_DIR/$SAMP/"${SAMP}.sra" ]; then
        echo "Beginning ${SAMP} fastq-transfer.."
	
	fastq_transfer_fromSRA
    else
	echo "Could not find ${SAMP} directory or .sra file"
	unload_modules 
	append_tracking_logs
	exit 1
    fi
    
    # Program will exit out if no bowtie alignments are made
    concatenate_fastq 
    alignSRAseq_to_poliokmer
    SECONDS=0
    blast_polioanno_NR
    spades_assembly
    fetch_metadata
    SECONDS_STOP=$SECONDS
    TIME_ELAPSED="$(($SECONDS_STOP / 60))m$(($SECONDS_STOP % 60))s"
    echo "$TIME_ELAPSED elapsed for $SAMP"

    mongo --quiet --host "${MONGOHOST}" -u "${MONGOUSER}" -p "${MONGOPASS}" --authenticationDatabase "admin" PASS \
    --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","passpipeline_time":("'$TIME_ELAPSED'")}},{upsert: true})'
else
    echo "${SAMP} found in MongoDB before processing"
fi
#### END CONTROL FLOW ####

# Housekeeping
#cd "${SCRATCH_DIR}"
# Commented out for now. Add in specific file removal to keep assembled contigs
#rm -r "${SCRATCH_DIR}/${SAMP}"
unload_modules

# Gather total runtime. Useful for distribution of processing.
date2=$(date +"%s")
diff=$(($date2-$date1))
echo "$(($diff / 60)) minutes and $(($diff % 60)) seconds have elapsed to process ${SAMP}" 

append_tracking_logs
exit
