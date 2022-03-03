"""

Test the script webservice-image-digest by calling this from 
the tests directory

cd compose_setup/scripts/tests
python test-webservice-image-digest.py

"""

import unittest

import subprocess

script_location = "../webservice-image-digest.py"

base_command = "python {}".format(script_location)
branch = "develop"
simple_tag = "digest_test"
annotated_tag = "1.12.0-beta.1"

class TestDigest(unittest.TestCase):

    def test_branch(self):
        cmd = "{} {}".format(base_command, branch)
        ret = subprocess.check_output(cmd, shell=True, universal_newlines=True).rstrip()
        self.assertEqual(ret, "sha256:52cf6b09e89a238bfd1d98dd01139442d67fcaaa377c179f315dd06555f7bcae")
        pass

    def test_simple_tag(self):
        cmd = "{} {}".format(base_command, simple_tag)
        ret = subprocess.check_output(cmd, shell=True, universal_newlines=True).rstrip()
        self.assertEqual(ret, "sha256:52cf6b09e89a238bfd1d98dd01139442d67fcaaa377c179f315dd06555f7bcae")
        pass

    def test_annotated_tag(self):
        cmd = "{} {}".format(base_command, annotated_tag)
        ret = subprocess.check_output(cmd, shell=True, universal_newlines=True).rstrip()
        self.assertEqual(ret, "sha256:e6dcfdc9ea351b57cde556ff3c68f96b838e8e30cdb4ee693a29b6ef16f3a4be")
        pass

if __name__ == '__main__':
    unittest.main()
