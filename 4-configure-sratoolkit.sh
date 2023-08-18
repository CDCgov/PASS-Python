###########################################################
# Download SRA Tools
###########################################################
#1. Fetch the tar file from the canonical location at NCBI:
wget --output-document sratoolkit.tar.gz https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-ubuntu64.tar.gz

#2. Extract the contents of the tar file:
tar -vxzf sratoolkit.tar.gz

#3. For convenience (and to show you where the binaries are) append the path to the binaries to your PATH environment variable:
#Path is different from document
# export PATH=$PATH:/docker/sratoolkit.3.0.1-ubuntu64/bin
#export PATH=$PATH:~/sratoolkit.3.0.1-ubuntu64/bin

# Append to the end of the file
echo "" | sudo tee -a /etc/profile
CURDIR=$(pwd)
PARM='export PATH="$PATH:'$CURDIR'/sratoolkit.3.0.5-ubuntu64/bin"'
echo $PARM | sudo tee -a /etc/profile

# Update shell 
sudo source  /etc/profile #.profile


#4. Verify that the binaries will be found by the shell:
which fastq-dump

#Should return:
#/Users/user/sratoolkit.3.0.1-ubuntu64/bin/fastq-dump


###########################################################
# Configure SRA Tools
###########################################################
# 03. Quick Toolkit Configuration · ncbi/sra-tools Wiki (github.com)
mkdir cache

vdb-config --simplified-quality-scores no                             --root
vdb-config --set repository/user/ad/public/root=/docker/cache         --root
vdb-config --set repository/user/default-path=/docker/ncbi            --root
vdb-config --set config/default=false                                 --root
vdb-config --set LIBS/GUID=41ca79e0-a6c2-4957-9c80-124e36901219       --root
vdb-config -p > vdb-config.txt                                        

###########################################################
# Test SRA Tools
###########################################################

# 6. Test that the toolkit is functional:
fastq-dump --stdout -X 2 SRR390728
#Within a few seconds, the command should produce this exact output (and nothing else):
#Read 2 spots for SRR390728
#Written 2 spots for SRR390728
#@SRR390728.1 1 length=72
#CATTCTTCACGTAGTTCTCGAGCCTTGGTTTTCAGCGATGGAGAATGACTTTGACAAGCTGAGAGAAGNTNC
#+SRR390728.1 1 length=72
#;;;;;;;;;;;;;;;;;;;;;;;;;;;9;;665142;;;;;;;;;;;;;;;;;;;;;;;;;;;;;96&&&&(
#@SRR390728.2 2 length=72
#AAGTAGGTCTCGTCTGTGTTTTCTACGAGCTTGTGTTCCAGCTGACCCACTCCCTGGGTGGGGGGACTGGGT
#+SRR390728.2 2 length=72
#;;;;;;;;;;;;;;;;;4;;;;3;393.1+4&&5&&;;;;;;;;;;;;;;;;;;;;;<9;<;;;;;464262


####################################################
# How to use prefetch and fasterq-dump to extract FASTQ-files from SRA-accessions
# https://github.com/ncbi/sra-tools/wiki/08.-prefetch-and-fasterq-dump
####################################################
# Download Accession
id="SRR000001"
# prefetch $id
# fastq-dump $id -O sra/$id

#Expected output
#spots read      : 470,985
#reads read      : 1,883,940
#reads written   : 707,026
#reads 0-length  : 468,635
#technical reads : 708,279

###############################################
# vdb-dump shows data from AWS
###############################################
vdb-dump --info $id
#acc    : DRR000001
#remote : https://sra-pub-run-odp.s3.amazonaws.com/sra/DRR000001/DRR000001
#size   : 596,137,898
#type   : Table
#platf  : SRA_PLATFORM_ILLUMINA
#SEQ    : 10,148,174
#SCHEMA : NCBI:SRA:Illumina:tbl:phred:v2#1.0.4
#UPD    : vdb-copy
#UPDVER : 2.3.5
#UPDDATE: Mar 19 2014 (3/19/2014 0:0)
#UPDRUN : Mon May 26 2014 6:19:29 AM (5/0/2014 0:0)

#############################################
# Cleanup
#############################################
rm sratoolkit.tar.gz --force
