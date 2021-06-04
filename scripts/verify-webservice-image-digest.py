#!/usr/bin/env python3
"""

This script is meant to help with verifying that the image created in CircleCI and pushed to quay
match what we download via the Docker client. This ensures there has been no "registry poisoning"
or modifications to our Docker image since we created it.

Depending on how you have configured your Docker client you may need to run this script via sudo,
it will download and inspect the Docker image as required.

"""

import argparse
import requests
import subprocess


parser = argparse.ArgumentParser(
  description='Verify that CircleCI (via S3) and quay.io have the same image digest for the Dockstore Webservice')
parser.add_argument('tag', type=str,
                    help='The git tag (or branch) you would like to verify')

args = parser.parse_args()

DOCKER_TAG_BASE = "quay.io/dockstore/dockstore-webservice"

def get_docker_digest(image_path):
  # takes an image path and returns the digest as reported by Docker CLI
  message = ""
  print("Pulling the image {}...".format(image_path))
  try:
      subprocess.check_output(["docker", "pull", image_path])
      message = str(subprocess.check_output(["docker", "inspect", "--format='{{index .RepoDigests 0}}'", image_path]))
  except subprocess.CalledProcessError as err:
      print(err)
      exit(1)
  loc = message.find('sha256')
  return message[loc+7:loc+71]

def get_commit_from_github(tagOrBranch):
  # takes a tag or branch and returns the latest commit for a branch or commit for a tag
  # try tag
  base_url = "https://api.github.com/repos/dockstore/dockstore"
  tag_url = "{}/{}/{}".format(base_url, "git/ref/tags", tagOrBranch)
  response = requests.get(tag_url)
  print("Gathering commit info from GitHub...")
  if (response.status_code == 200):
    print('Found commit for a tag!')
    return response.json()['object']['sha']
  # try branch
  branch_url = "{}/{}={}".format(base_url, "commits?sha", tagOrBranch)
  response = requests.get(branch_url)
  if (response.status_code == 200):
    print("Found commit for a branch!")
    return response.json()[0]['sha']
  print("No commit for that tag or branch found!")
  exit(1)

def get_digest_from_s3(tag, commit):
  # downloads the image-digest.txt from a directory in S3
  print("Downloading the image-digest.txt stored in S3...")
  base_url = "https://gui.dockstore.org"
  response = requests.get("{}/{}-{}/image-digest.txt".format(base_url, tag, commit[0:7]))
  if (response.status_code != 200):
    print("The image-digest.txt was not found in S3, did the build succeed?")
    exit(1)
  # There is a newline at the end of the file we rstrip
  return response.text.rstrip()

if __name__ == "__main__":
  print("Checking image digests from CircleCI via S3 and quay.io using the Docker client...")
  # slashes are replaced with _ in docker image tags
  commit = get_commit_from_github(args.tag)
  print(commit)
  docker_digest = get_docker_digest("{}:{}".format(DOCKER_TAG_BASE, args.tag.replace("/", "_")))
  circle_digest = get_digest_from_s3(args.tag, commit)
  print("From CircleCI: ", circle_digest)
  print("From quay.io:  ", docker_digest)
  if (docker_digest == circle_digest):
    print("SUCCESS!!! The digests match!")
    exit(0)
  else:
    print("FAILURE!!! The digests do NOT match!")
  exit(1)
