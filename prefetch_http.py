
###############################################
#   creates /cache1/{sra}/{sra}.sra
###############################################

import time
import datetime
import os   
import subprocess
import json
import response
import downloader
import jsons
import shutil
import tasklogger
import mongologger
from pipeline_paths import PipelinePaths

from dataclasses import dataclass
from typing import List


from typing import Optional, List
import datetime

import requests
import globals
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


def prefetch(sra: str):
   tic: float = time.perf_counter()

   paths = PipelinePaths(sra)

   if  os.path.exists(paths.cache1_dir) is False:
      os.mkdir(paths.cache1_dir)
      
   url = f"https://locate.ncbi.nlm.nih.gov/sdl/2/retrieve?acc={sra}&accept-alternate-locations=yes&filetype=sra"
   #https://urllib3.readthedocs.io/en/latest/reference/urllib3.util.html#module-urllib3.util.retry
   session = requests.Session()
   retry = Retry(connect=15, backoff_factor=1)
   adapter = HTTPAdapter(max_retries=retry)
   session.mount('http://', adapter)
   session.mount('https://', adapter)

   httpResponse = session.get(url)

   if httpResponse.status_code != 200:
      print(f"Error:{sra}")

   else:
      dic = json.loads(httpResponse.text)
      map = jsons.load(dic,response.NCBI)
      locations = []
      link = ""
      size = ""
      for result in map.result:
         for file in result.files:
             if file.name == sra:
               for location in file.locations:
                  if location.service == "s3":
                     link = location.link
                     size = file.size
                     SRAReleaseDate = file.modificationDate
               print(sra,size,link)

      tasklogger.logmetric("prefetch-http",sra,"Size",size)
      tasklogger.logmetric("prefetch-http",sra,"SRAReleaseDate",SRAReleaseDate) # 2020-05-24T19:51:55.000+00:00

      dlSize = "FAIL"
      if link == "":
         print(f"Link Error:{sra}")  
      else:
         dlSize = downloader.download_file(link, paths.sra_file, True)

      if dlSize == size:
         print(f"Downloaded:{sra}\t{size}=={dlSize}")
      else:
         print(f"Download Error:{sra}\t{size}!={dlSize}")
         #loop

   toc: float = time.perf_counter()
   tasklogger.logtask_with_command("prefetch-http",sra,dlSize,tic,toc,link)

   tasklogger.logmetric("prefetch-http",sra,"ReadHits",None)
   tasklogger.logmetric("prefetch-http",sra,"ReadHitsCount",None)
   tasklogger.logmetric("prefetch-http",sra,"ReadBlastHits",None)
   tasklogger.logmetric("prefetch-http",sra,"ReadNRHits",None)
   tasklogger.logmetric("prefetch-http",sra,"RegionHits",None) 
   
   tasklogger.logmetric("prefetch-http",sra,"SPAdesContigs",None)
   tasklogger.logmetric("prefetch-http",sra,"ContigHits",None)
   tasklogger.logmetric("prefetch-http",sra,"ContigRegionHits",None)  
 









