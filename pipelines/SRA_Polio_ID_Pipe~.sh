#!/bin/bash -l
source /etc/profile

# Version 181217, 190812
# SRA_download and analysis for viral read search
# cd to directory of choice
# script will make folder with SRA accession_number
# usage ./SRA_Polio_ID_Pipe.sh SRA_accession_number
# ./SRA_Polio_ID_Pipe.sh DRR001793

#############################################################
# Setting cluster
#############################################################
#$ -o Viral_SRA_Log.out # name of .out file
#$ -e Viral_SRA_Log.err # name of .err file
#$ -pe smp 4-6 # number of cores to use from 4-16
#$ -q all.q # where to direct query submission
#$ -cwd
##$ -m e -M yqd9@cdc.gov #email start, abort and end of run
date
#############################################################
#############################################################
date1=$(date +"%s")
dateStart=$(date)

#date2=$(date +"%s")
#dateEnd=$(date)
#diff=$(($date2-$date1))
#echo -e "Run_END\t$dateEnd\t$date2" >> $OUTFOLDER/$RUN/Log/$SAMP.log
#echo "$(($diff / 60)) minutes and $(($diff % 60)) seconds elapsed" >> $OUTFOLDER/$RUN/Log/$SAMP.log

module load sratoolkit/2.9.1
module load mongo/3.4.4
module load bowtie2
module load seqtk/1.2
module load ncbi-blast+
module load SPAdes

SAMP=$1

MONGOHOST="ncbs-dev-05.biotech.cdc.gov"

HAVEIT=$(mongo --quiet $MONGOHOST/PASS --eval 'db.data.find({"Run":"'${SAMP}'"}).limit(1).size()')
if [ "$HAVEIT" == 0 ]; then
    echo "DON'T have it, will process!!!"

    HOMESTART=$(pwd)
    OUTDIR=/scicomp/groups/OID/NCIRD-OD/OI/ncbs/projects/PASS/SRA
    mkdir $OUTDIR/$SAMP
    cd $OUTDIR/$SAMP
    #fastq-dump -O $OUTDIR/$SAMP $SAMP
    prefetch $SAMP
    mv ~/ncbi/public/sra/$SAMP.sra .
    fastq-dump $SAMP.sra

    INDEX=/scicomp/groups/OID/NCIRD-OD/OI/ncbs/projects/Reference/polio/PASS/PASS_Anno

    # sensitive "PolioAnno"
    #bowtie2 -p16 --very-sensitive-local -N 1 -t --quiet -x $INDEX/PassAll -U $SAMP.fastq --un $SAMP.NonPassAll.fq --al $SAMP.PassAll.fq -S $SAMP.PassAll.sam
    bowtie2 -p16 --sensitive-local -N 1 -t --quiet -x $INDEX/PolioAnnoKmer/PolioAnno_kmer -U $SAMP.fastq --un $SAMP.NoPolio.fq --al $SAMP.Polio.fq -S $SAMP.Polio.sam

    if [ -s $SAMP.Polio.fq ]; then

        #####Potential Polio Read Hits
        echo "FILE has potentil polio hits"
        mongo --quiet ncbs-dev-05.biotech.cdc.gov/PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadHits":"yes"}},{upsert: true})'
        seqtk seq -a $SAMP.Polio.fq >$SAMP.Polio.fasta
        READCOUNT=$(grep -c "^>" $SAMP.Polio.fasta)
        mongo --quiet ncbs-dev-05.biotech.cdc.gov/PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadHitsCount":"'$READCOUNT'"}},{upsert: true})'

        #####Blasting reads and running SPAdes
        # blast read to annotated polio reference
        blastn -db $INDEX/PolioAnnoBlast/PolioAnno -query $SAMP.Polio.fasta -num_threads 8 -num_alignments 1 -outfmt "6 qseqid sseqid pident qlen length mismatch gapopen qstart qend sstart send evalue bitscore qseq sseq" >>$SAMP.reads.out

        if [ -s $SAMP.reads.out ]; then
            $INDEX/addSabinLocation.pl $SAMP.reads.out >$SAMP.anno.out
            mongo --quiet ncbs-dev-05.biotech.cdc.gov/PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadBlastHits":"yes"}},{upsert: true})'
            rm $SAMP.reads.out
        else
            echo "READ BLAST FILE EMPTY"
            mongo --quiet ncbs-dev-05.biotech.cdc.gov/PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadBlastHits":"no"}},{upsert: true})'
        fi

        # blast read to genbank nr
        if (($READCOUNT > 2000)); then
            echo "Read counts are too large to BLAST against NR"
            mongo --quiet ncbs-dev-05.biotech.cdc.gov/PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadNRHits":"NA"}},{upsert: true})'
        else
            echo "Will BLAST to NR"
            export BLASTDB=/blast/db
            blastn -task blastn -db nt -query $SAMP.Polio.fasta -num_threads 8 -num_alignments 1 -outfmt "6 qseqid sseqid pident qlen length mismatch gapopen qstart qend sstart send evalue bitscore qseq sseq" >>$SAMP.NR.out
            sed -i '1s/^/seqid\tsseqid\tpident\tqlen\tlength\tmismatch\tgapopen\tqstart\tqend\tsstart\tsend\tevalue\tbitscore\tqseq\tsseq\n/' $SAMP.NR.out

            if [ -s $SAMP.NR.out ]; then
                mongo --quiet ncbs-dev-05.biotech.cdc.gov/PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadNRHits":"yes"}},{upsert: true})'
            else
                echo "READ NR BLAST FILE EMPTY"
                mongo --quiet ncbs-dev-05.biotech.cdc.gov/PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadNRHits":"no"}},{upsert: true})'
            fi
        fi
        ####module load SPAdes/3.7.0
        mkdir SPAdes_"$SAMP"
        spades.py -t 6 -s "$SAMP".Polio.fq -o SPAdes_"$SAMP"
        cd SPAdes*

        if [ -s contigs.fasta ]; then
            echo "Contigs Assembled"
            mongo --quiet ncbs-dev-05.biotech.cdc.gov/PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","SPAdesContigs":"yes"}},{upsert: true})'
            export BLASTDB=/blast/db
            blastn -task blastn -db nt -query contigs.fasta -evalue 1e-10 -num_threads 16 -num_alignments 1 -max_hsps 1 -outfmt '6 qseqid pident length qlen slen mismatch gapopen qstart qend sstart send evalue bitscore sgi sacc staxids sblastnames stitle' -out Blast-NT.out
            sed -i '1s/^/qseqid\tpident\tlength\tqlen\tslen\tmismatch\tgapopen\tqstart\tqend\tsstart\tsend\tevalue\tbitscore\tsgi\tsacc\tstaxids\tsblastnames\tstitle\n/' Blast-NT.out
        else
            echo "No Contigs Assembled"
            mongo --quiet ncbs-dev-05.biotech.cdc.gov/PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","SPAdesContigs":"no"}},{upsert: true})'
        fi

        #####Fetch Metadata
        echo "FILE not empty fetching metadata"
        module load Entrez/E-utilities

        cd $OUTDIR/$SAMP
        mkdir metadata
        cd metadata
        #Fetch main SRA metadata in runinfo format
        efetch -db sra -id $SAMP -format runinfo >$SAMP.csv 2>$SAMP.err
        HEADER=$(head -n1 $SAMP.csv)
        METADATA=$(cat $SAMP.csv | awk -v pat="$SAMP" '$1 ~ pat')
        IFS=',' read -r -a METAfoo <<<$METADATA

        LOCATION=$(esearch -db sra -query $SAMP | elink -target biosample | efetch -format docsum | xtract -pattern DocumentSummary -block Attribute -if Attribute@attribute_name -equals geo_loc_name -element Attribute)

        HEAD="location"
        FINALHEADER="$HEADER,$HEAD"
        FINALMETADATA="$METADATA,$LOCATION"
        echo -e "$FINALHEADER \n $FINALMETADATA" >$SAMP.csv

        mongoimport --host $MONGOHOST -d PASS -c data --type csv --file $SAMP.csv --headerline

        BIOSAMPLE=$(efetch -db biosample -id ${METAfoo[25]} -format native | sed 's/"//g')
        echo $BIOSAMPLE >$SAMP.biosample.txt

        echo 'db.data.findOneAndUpdate({"Run":"'${METAfoo[0]}'"},{$set:{"bioSampleDetails": "'$BIOSAMPLE'"}},{upsert: true})' >$SAMP.js
        mongo --quiet --port 27017 --host $MONGOHOST PASS <$SAMP.js

    else
        echo "FILE EMPTY" # remove file sra file and folder
        mongo --quiet ncbs-dev-05.biotech.cdc.gov/PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadHits":"no"}},{upsert: true})'
        mongo --quiet ncbs-dev-05.biotech.cdc.gov/PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadHitsCount":"0"}},{upsert: true})'
        mongo --quiet ncbs-dev-05.biotech.cdc.gov/PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadBlastHits":"no"}},{upsert: true})'
        mongo --quiet ncbs-dev-05.biotech.cdc.gov/PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","ReadNRHits":"no"}},{upsert: true})'
        mongo --quiet ncbs-dev-05.biotech.cdc.gov/PASS --eval 'db.data.findOneAndUpdate({"Run":"'${SAMP}'"},{$set:{"Run": "'$SAMP'","SPAdesContigs":"no"}},{upsert: true})'
        rm -r $OUTDIR/$SAMP
    fi

else
    echo "Sample already processed"
fi

exit
