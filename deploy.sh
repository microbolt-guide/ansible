#!/bin/sh -e

ANSIBLE_CONFIG=./ansible.cfg \
    ansible-playbook site.yaml "$@"