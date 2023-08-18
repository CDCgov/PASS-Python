
import datetime 
import pyodbc
import pandas
import globals
from google.cloud import secretmanager
import requests
import pyodbc
import subprocess
import mongologger

#get secret
client = secretmanager.SecretManagerServiceClient()
name = "projects/30811739638/secrets/pass-sql-password/versions/1"
response = client.access_secret_version(name=name)
globals.password = response.payload.data.decode('UTF-8')


metadata_server = "http://metadata/computeMetadata/v1/instance/"
metadata_flavor = {'Metadata-Flavor' : 'Google'}
gce_id = requests.get(metadata_server + 'id', headers = metadata_flavor).text
gce_name = requests.get(metadata_server + 'hostname', headers = metadata_flavor).text
gce_machine_type = requests.get(metadata_server + 'machine-type', headers = metadata_flavor).text

globals.vm = gce_name.split(".")[0] # "sra--n2-highcpu-16--local-ssd"

globals.server = "34.73.29.255"

##############################################################################
#Add VM to SQL Server Network; WIPES OUT ALL OTHER IPS !!!-- including mine
#command = f'''gcloud compute instances describe {gce_name.split(".")[0]} \
#  --zone={gce_name.split(".")[1]} \
#  --project={gce_name.split(".")[3]} \
#  --format="value(networkInterfaces[0].accessConfigs[0].natIP)"'''
#result = subprocess.run(command, shell=True, capture_output=True)
#publicIp = result.stdout.decode().rstrip()
#command = f'''gcloud sql instances patch "pass-python" --authorized-networks="{publicIp}/32"'''
#result = subprocess.run(command, shell=True, capture_output=True)    

#Get Run Index
connection = pyodbc.connect("DRIVER={ODBC Driver 17 for SQL Server};"                            
                            "SERVER=34.73.29.255;"                            
                            "DATABASE=timings;"                            
                            "UID=sqlserver;"                  
                            f"PWD={globals.password};")


cursor=connection.cursor()
cursor.execute('select MAX(RUN) from dbo.RUNS')

globals.run = cursor.fetchone()[0] + 1

print(f"Run={globals.run}")

def logtask(task: str, sra: str, bytes: float,  tic:float, toc:float):
   logtask_with_command(task,sra,bytes,tic,toc,None)

def logtask_with_command(task: str, sra: str, bytes: float,  tic:float, toc:float, command: str):
   
   dt = datetime.datetime.now().strftime("%Y-%b-%d %H:%M:%S")
   msg = f"{dt} {task} {sra} {bytes} {(toc - tic):.3f}\n"
   print(msg)

   with open("timings.log", "a") as myfile:
      myfile.write(msg)

   seconds = toc - tic

   sql = f'''INSERT INTO [dbo].[Runs]
           ([Run]
           ,[Samples]
           ,[VM]
           ,[DateTime]
           ,[Task]
           ,[SRA]
           ,[Bytes]
           ,[Seconds]
           ,[Comments])
     VALUES
           ('{globals.run}',
           '{globals.samples}',
           '{globals.vm}',
           '{datetime.datetime.now().strftime("%Y/%m/%d %H:%M:%S")}',
           '{task}',
           '{sra}',
           '{bytes}',
           '{seconds}',
           '{command}')'''

   # cursor=connection.cursor()
   # cursor.execute(sql)
   # connection.commit()
   gb = float(bytes)/1024/1024/1024

   set = { 
      "$set": 
      { f"Tasks.{task}": 
         {
           #  "prefetch-http": None, 
             "seconds": (toc - tic), 
             "bytes": bytes,
             "gb": gb,
             "command": command
         }
      }
   }
    
   mongologger.update_one_by_set(task, sra, set)

# this will eventually write to 
# Google Cloud Datastore
# DynamoDB
def logmetric(task: str, sra: str, name: str, value: str):
   #task is unused
   dt = datetime.datetime.now().strftime("%Y-%b-%d %H:%M:%S")
   msg = f"{dt} {task} {sra} {name} {value}\n"
   print(msg)

   with open("metric.log", "a") as myfile:
      myfile.write(msg)

   mongologger.findOneAndUpdate(task, sra, name, value)
