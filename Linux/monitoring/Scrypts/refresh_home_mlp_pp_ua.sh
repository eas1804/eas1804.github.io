#!/bin/bash

DOMEN=home.mlp.pp.ua

RESULT=$(dig $DOMEN A +short)

nft -f /etc/nftables.conf
nft add    rule inet filter input ip saddr $RESULT accept



exit 0
