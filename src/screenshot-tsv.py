#! /usr/bin/python3
# Takes screenshots of all URLs in the recommendations catalogue. 
from os import path, listdir
from hashlib import md5
from subprocess import Popen
import random

def get_repo():
    repo = "."
    while not path.exists(path.join(repo, ".git")):
        repo = path.join("..")
    return repo

linksdir = path.join(get_repo(), "links")
links = set()
for filename in listdir(linksdir):
    with open(path.join(linksdir, filename)) as f:
        for line in f:
            if not line or line[0] == "#": continue
            links |= {bytes(link, "ascii") for link in line.split()}

screenshooters = []
for link in links:
    screenshooter = Popen([path.join(get_repo(), "src", "screenshot-url"), link])
    screenshooters.append(screenshooter)
    # This is necessary so as not to overburden your system.
    random.choice(screenshooters).wait()

for proc in screenshooters: proc.wait()
