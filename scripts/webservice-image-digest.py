#!/usr/bin/env python3
"""

This script will gather a sha256 digest created by CircleCI and uploaded to S3
then print it to the terminal. This is meant to simplify the process of using
images by digest as opposed to by tag and will also guarantee the image pulled
from Quay has not been changed since being built.

Assets in S3 follow the directory structure: `./branch-shortcommit/image-digest.txt`

Provide a git tag, branch, or branch-shorthash

The output is formatted to be easily used to select a specific image digest via docker

sha256:08c67131daf6109fadb19d994d753ede7ae28e41c675322e2980327597bcb665

"""

import argparse
import requests
import string

parser = argparse.ArgumentParser(
  description='Gather an image digest for the Dockstore Webservice from S3 as created by CircleCI')
parser.add_argument('tag', type=str,
                    help='The git tag, branch, or branch-hash of a Webservice commit')

args = parser.parse_args()

DOCKER_TAG_BASE = "quay.io/dockstore/dockstore-webservice"

def get_commit_from_tag_url(tag_url):
  # takes a tag url and gets the commit hash it is pointed at
  response = requests.get(tag_url)
  return response.json()['object']['sha']

def get_commit_from_github(tag_or_branch):
  # takes a tag or branch and returns the latest commit for a branch or commit for a tag
  # try tag
  base_url = "https://api.github.com/repos/dockstore/dockstore"
  tag_url = "{}/{}/{}".format(base_url, "git/ref/tags", tag_or_branch)
  response = requests.get(tag_url)
  if (response.status_code == 200):
    # simple tag
    if (response.json()['object']['type'] == "commit"):
      return response.json()['object']['sha']
    else:
      # annotated tag
      return get_commit_from_tag_url(response.json()['object']['url'])
  # try branch
  branch_url = "{}/{}={}".format(base_url, "commits?sha", tag_or_branch)
  response = requests.get(branch_url)
  if (response.status_code == 200):
    return response.json()[0]['sha']
  print("No commit for that tag or branch found!")
  exit(1)

def get_digest_from_s3(directory):
  # downloads the image-digest.txt from a directory in S3
  base_url = "https://gui.dockstore.org"
  digest_url = "{}/{}/image-digest.txt".format(base_url, directory.replace("/","_"))
  response = requests.get(digest_url)
  if (response.status_code != 200):
    print("Expected a file at {}".format(digest_url))
    print("The image-digest.txt was not found in S3, did the build succeed?")
    exit(1)
  # There is a newline at the end of the file we rstrip
  return response.text.rstrip()

if __name__ == "__main__":
  # slashes are replaced with _ in docker image tags
  # check to see if input includes a dash followed by 7 chars
  parsed = args.tag.split('-')
  if len(parsed) >= 2 and len(parsed[-1]) == 7 and all(c in string.hexdigits for c in parsed[-1]):
    directory = args.tag
  else:
    commit = get_commit_from_github(args.tag)
    directory = "{}-{}".format(args.tag, commit[0:7])
  circle_digest = get_digest_from_s3(directory)
  print("sha256:{}".format(circle_digest))
  exit(0)
