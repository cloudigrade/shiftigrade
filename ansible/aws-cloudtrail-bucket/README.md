aws-cloudtrail-bucket
=========

This role can create and delete the s3 bucket and sqs queue needed to allow
cloudtrail to post events to an s3 bucket and send notifications to a queue to
indicate objects have been created in the bucket.

Requirements
------------

This module assumes that `/usr/bin/env python` (whatever `python` is in your current environment) can import boto3 and that the aws cli is installed and in your path.

Role Variables
--------------

`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` must be set in the environment. A prefix must be provided for the s3 bucket and sqs queue with `aws_prefix` passed to `ansible-playbook`.


License
-------

GPLv3
