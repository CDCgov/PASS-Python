import os


root = os.path.abspath(os.getcwd()) 

cache1Root = "/mnt/cache1"
cache2Root = "/mnt/cache2"
tempRoot =   "/mnt/temp"

run = 0
samples = 0
vm = "sra--n2-highcpu-16--local-ssd"
server = "34.73.29.255"
password = "xxx"

mongodb_connection_string = "mongodb+srv://<username>:<password>@pass-serverlessinstance.i0rkhos.mongodb.net/?retryWrites=true&w=majority"


PASS_Anno=f"{tempRoot}/PASS_Anno"

blastDBPath = f"{PASS_Anno}/PolioAnnoKmer/PolioAnno_kmer"

threads = (os.cpu_count() * 2)

def file_size_gt_0(path: str):

   if os.path.isfile(path) == False:
      return False
   
   if os.stat(path).st_size > 0:
      return True
   else:
      return False
