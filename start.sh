#!/bin/bash
fallocate -l ${DATABASE_SIZE}GB /var/ardb/data/kreon.dat
mkfs.kreon.single.sh /var/ardb/data/kreon.dat 1 1
ardb-server /etc/ardb.conf