import jsons
from dataclasses import dataclass
from typing import List
from typing import Optional
from datetime import datetime

@dataclass
class Location:
    service: str
    region: str
    link: str
    pay_required: Optional[str]


@dataclass
class File:
    object: str
    accession: str
    type: str
    name: str
    size: str
    md5: str
    modificationDate: datetime
    locations: List[Location]
    noqual: Optional[str]

@dataclass
class Result:
    bundle: str
    status: str
    msg: str
    files: List[File]

@dataclass
class NCBI:
    version: str
    result: List[Result]
