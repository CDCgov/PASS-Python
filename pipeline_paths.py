import globals

class PipelinePaths:
    def __init__(self, sra):


        self.cache1_dir = f"{globals.cache1Root}/{sra}"
        self.cache2_dir = f"{globals.cache2Root}/{sra}"
        self.temp_dir = f"{globals.tempRoot}/{sra}"
        self.sra_file =  f"{globals.cache1Root}/{sra}/{sra}.sra"

        self.fastq_file = f"{globals.cache2Root}/{sra}/{sra}.fastq"
        self.nopolio_fq_file = f"{globals.cache1Root}/{sra}/{sra}.NoPolio.fq"
        self.polio_fq_file = f"{globals.cache1Root}/{sra}/{sra}.Polio.fq"
        self.polio_sam_file = f"{globals.cache1Root}/{sra}/{sra}.Polio.sam"
        self.polio_fasta_file = f"{globals.cache2Root}/{sra}/{sra}.Polio.fasta"

        self.blast_n_out_file   = f"{globals.cache1Root}/{sra}/{sra}.N.out" 
        self.anno_out_file     = f"{globals.cache2Root}/{sra}/{sra}.anno.out"
       
        self.spades_dir   = f"{globals.cache2Root}/{sra}/Spades"
        self.spades_contig_fasta_file = f"{globals.cache2Root}/{sra}/Spades/contigs.fasta"
        self.spades_contig_n_out_file = f"{globals.cache1Root}/{sra}/spades.contigs.N.out"        
        self.spades_contig_anno_n_out_file = f"{globals.cache2Root}/{sra}/spades.anno.N.out"          
