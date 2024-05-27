#!/bin/bash

DOMEN=home.mlp.pp.ua

RESULT=$(dig $DOMEN A +short)
/usr/sbin/iptables -D INPUT -p tcp -s $RESULT -m tcp --dport 22 -j ACCEPT -m comment --comment "$DOMEN"  2>/dev/nul
/usr/sbin/iptables -A INPUT -p tcp -s $RESULT -m tcp --dport 22 -j ACCEPT -m comment --comment "$DOMEN"


exit 0
