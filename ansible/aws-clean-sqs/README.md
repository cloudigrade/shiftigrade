aws-clean-sqs
=============

This role either purges the messages from all sqs queues created with the
`aws_prefix` specified, or can delete the queues if desired.

Requirements
------------

This module assumes that `/usr/bin/env python` (whatever `python` is in your
current environment) can import boto3 and that the aws cli is installed and in
your path.

Role Variables
--------------

`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` must be set in the environment.
A prefix must be provided to identify the queues to clean up with `aws_prefix`
passed to `ansible-playbook`.


License
-------

GPLv3
