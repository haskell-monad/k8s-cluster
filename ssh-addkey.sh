#!/bin/sh


ssh-keygen -N '' -f /root/.ssh/id_rsa

ansible-playbook -i hosts _ssh.yml
