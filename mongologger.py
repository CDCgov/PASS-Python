from google.cloud import secretmanager
from pymongo.mongo_client import MongoClient
from pymongo.server_api import ServerApi
import pymongo
import time
import os   
import subprocess
import json
import response
import downloader
import globals
import jsons
import shutil
import tasklogger
import mongologger
import csv
import pandas as pd

from pipeline_paths import PipelinePaths

from dataclasses import dataclass
from typing import List


from typing import Optional, List
from datetime import datetime

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

client = secretmanager.SecretManagerServiceClient()
name = "projects/30811739638/secrets/pass-mongodb-connectionstring/versions/1"
value = client.access_secret_version(name=name)
globals.mongodb_connection_string = value.payload.data.decode('UTF-8')
#uri = "mongodb+srv://<username>:<password>@pass-serverlessinstance.i0rkhos.mongodb.net/?retryWrites=true&w=majority"
# Create a new client and connect to the server
uri = globals.mongodb_connection_string
client = MongoClient(uri, server_api=ServerApi('1'))
# Send a ping to confirm a successful connection
try:
   client.admin.command('ping')
   print("Pinged your deployment. You successfully connected to MongoDB!")
   print(f"pymongo Client Version:{pymongo.__version__}")
except Exception as e:
   print(e)

def insertSraDocument(task: str, sra: str, raw: str):

   db = client.get_database("PASS")
   
   dic = json.loads(raw)
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

   print(sra,size,link, SRAReleaseDate)   

   findOneAndUpdate(task,sra,"SRAReleaseDate",file.modificationDate)


def findOneAndUpdate(task: str, sra: str, name: str, value: str):
   db = client.get_database("PASS")
   db.data.find_one_and_update(
      {
         "Run": sra,
      },
      {"$set": {name: value}},      
      upsert=True
   )
   print("")

def update_one_by_set(task: str, sra: str, set):

   db = client.get_database("PASS")
   db.data.update_one(
      {
         "Run": sra,
      },
      set,      
      upsert=True
   )
   print("")
   
def update_one(task: str, sra: str, name: str, element:str, value: str):
   db.data.update_one(
      {
         "Run": sra,
      },
      {"$set": { f"{name}.1": value}},      
      upsert=True
   )   

def importFile(task: str, sra: str, path: str, collectionName: str, filetype: str):
   
   db = client.get_database("PASS")
   collection = db[collectionName]

   collection.delete_many(      
      {
         "Run": sra
      }) #filter must be an instance of dict, bson.son.SON, or any other type that inherits from collections.Mapping

   json_strings  = []
   df = pd.read_csv(path, sep='\t')

   for index, row in df.iterrows():
      data = {}
      data["Run"] = sra
      for col in df.columns:
         data[col] = row[col]

      json_strings.append(json.dumps(data))

   documents = [json.loads(json_string) for json_string in json_strings]
   collection.insert_many(documents)

   print("")

def queryDistinct(task: str, sra: str,  collectionName: str, field:str,  query: str):
   
   db = client.get_database("PASS")
   collection = db[collectionName]

   result = collection.distinct(field, query)
   
   return result

def clearCollection(task: str, collectionName: str):

   db = client.get_database("PASS")
   collection = db[collectionName]
   collection.delete_many({})