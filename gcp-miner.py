import time
import datetime
import os   
import subprocess
import json
import response
import downloader
import jsons
import shutil
from pipeline_paths import PipelinePaths

from dataclasses import dataclass
from typing import List


from typing import Optional, List
import datetime

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


with open('sralist-10000.txt', 'r') as file:
   sz = file.read()
   a = sz.split("\n")

   cnt = 0
   for sra in a:
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
                     if location.service == "gs":
                        link = location.link
                        size = file.size
                        
                        print(sra,size,link)
                        break

      #    tasklogger.logmetric("prefetch-http",sra,"Size",size)
      #    tasklogger.logmetric("prefetch-http",sra,"SRAReleaseDate",SRAReleaseDate) # 2020-05-24T19:51:55.000+00:00
      #
      #    dlSize = "FAIL"
      #    if link == "":
      #        print(f"Link Error:{sra}")  
      #    else:
      #        dlSize = downloader.download_file(link, paths.sra_file, True)
      #
      #    if dlSize == size:
      #        print(f"Downloaded:{sra}\t{size}=={dlSize}")
      #    else:
      #        print(f"Download Error:{sra}\t{size}!={dlSize}")
      #        #loop
      #