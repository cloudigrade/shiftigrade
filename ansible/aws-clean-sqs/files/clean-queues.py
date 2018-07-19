#!/usr/bin/env python
"""Simple CLI program to either purge messages from queues or delete them."""

import argparse

import boto3


def clean_queues(aws_prefix, delete_q):
    """Purge any messages off of queues that have the aws_prefix.

    Optionally, delete the queue instead of purging the messages if "delete_q"
    is True.
    """
    client = boto3.client('sqs')
    for q_url in client.list_queues(QueueNamePrefix=aws_prefix).get('QueueUrls', []):
        if delete_q:
            client.delete_queue(QueueUrl=q_url)
        else:
            client.purge_queue(QueueUrl=q_url)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='The aws prefix for the queue names to be purged.')
    parser.add_argument(
        '--prefix ',
        required=True,
        default=None,
        action='store',
        dest='prefix',
        type=str,
        help=('Prefix used to name sqs queues.')
    )
    parser.add_argument(
        '--delete',
        required=False,
        default=False,
        action='store',
        dest='delete_q',
        type=bool,
        help=('Instead of only purging messages, delete the queues.')
    )
    args = parser.parse_args()

    clean_queues(args.prefix, args.delete_q)
