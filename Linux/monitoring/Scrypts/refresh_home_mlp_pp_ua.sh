#!/bin/bash

DOMEN=home.mlp.pp.ua

RESULT=$(dig $DOMEN A +short)

/usr/sbin/nft -f /etc/nftables.conf
/usr/sbin/nft add    rule inet filter input ip saddr $RESULT accept



exit 0
