# https://gist.github.com/odinokov/b511e6f73581982c88c432c82def9589#file-download_file-py
import os
import requests
import shutil
import subprocess
from tqdm import tqdm


def download_file(url: str, file_path: str, showStatusBar: bool):
   """
   Downloads a file from the given URL and saves it to the specified file path.
   Shows a progress bar using the tqdm library.
   """
   # Get the file name from the URL
   #file_name = os.path.basename(url)

   # Append .tmp extension to the file name
   tmp_file_path = os.path.join(file_path + ".tmp")

   # Check if the file already exists and has the correct size
   if os.path.exists(file_path) and os.path.getsize(file_path) == int(requests.head(url).headers["Content-Length"]):
      print(f"Skipping download, file {file_path} already exists.")
      return os.path.getsize(file_path)

   # Check if the temporary file already exists and resume download
   resume_byte_pos = 0
   if os.path.exists(tmp_file_path):
      resume_byte_pos = os.path.getsize(tmp_file_path)
      print(f"Resuming download from byte position {resume_byte_pos}.")

   # Send a GET request to the URL and get the response as a stream
   headers = {"Range": f"bytes={resume_byte_pos}-"}
   with requests.get(url, stream=True, allow_redirects=True, headers=headers) as response:
      # Raise an exception if the response status code is not in the 200-299 range
      if not response.ok:
         response.raise_for_status()

      # Get the total size of the file from the response headers
      total_size = int(response.headers.get("content-length", 0))

      # Open the temporary file in binary write mode
      with open(tmp_file_path, "ab") as f, tqdm(total=total_size, initial=resume_byte_pos, unit="B", unit_scale=True, desc=file_path,disable=(not showStatusBar)) as pbar:
         # Read the response in chunks and write each chunk to the file
         for chunk in response.iter_content(chunk_size=8192):
               if chunk:
                  f.write(chunk)
                  pbar.update(len(chunk))

   # Move the temporary file to the target file upon successful download
   shutil.move(tmp_file_path, file_path)
   print(f"Download of {file_path} complete.")
   existSize = os.path.getsize(file_path)
   return str(existSize)