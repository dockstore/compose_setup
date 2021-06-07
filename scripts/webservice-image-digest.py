#!/usr/bin/env python3
"""

This script will gather a sha256 digest created by CircleCI and uploaded to S3
then print it to the terminal. This is meant to simplify the process of using
images by digest as opposed to by tag and will also guarantee the image pulled
from Quay has not been changed since being built.

"""

import argparse
import requests
import subprocess


parser = argparse.ArgumentParser(
  description='Gather an image digest for the Dockstore Webservice from S3 as created by CircleCI')
parser.add_argument('tag', type=str,
                    help='The git tag (or branch)')

args = parser.parse_args()

DOCKER_TAG_BASE = "quay.io/dockstore/dockstore-webservice"

def get_commit_from_github(tag_or_branch):
  # takes a tag or branch and returns the latest commit for a branch or commit for a tag
  # try tag
  base_url = "https://api.github.com/repos/dockstore/dockstore"
  tag_url = "{}/{}/{}".format(base_url, "git/ref/tags", tag_or_branch)
  response = requests.get(tag_url)
  if (response.status_code == 200):
    return response.json()['object']['sha']
  # try branch
  branch_url = "{}/{}={}".format(base_url, "commits?sha", tag_or_branch)
  response = requests.get(branch_url)
  if (response.status_code == 200):
    return response.json()[0]['sha']
  print("No commit for that tag or branch found!")
  exit(1)

def get_digest_from_s3(tag, commit):
  # downloads the image-digest.txt from a directory in S3
  base_url = "https://gui.dockstore.org"
  response = requests.get("{}/{}-{}/image-digest.txt".format(base_url, tag, commit[0:7]))
  if (response.status_code != 200):
    print("The image-digest.txt was not found in S3, did the build succeed?")
    exit(1)
  # There is a newline at the end of the file we rstrip
  return response.text.rstrip()

if __name__ == "__main__":
  # slashes are replaced with _ in docker image tags
  commit = get_commit_from_github(args.tag)
  circle_digest = get_digest_from_s3(args.tag, commit)
  print("sha256:{}".format(circle_digest))
  exit(0)
