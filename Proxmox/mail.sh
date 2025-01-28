echo "smtp.gmail.com  report.backup@gmail.com:zwgghkgmgqczshjw">> /etc/postfix/sasl_passwd

apt install libsasl2-modules -y
echo "root@pam report1.backup1@gmail.com" >> /etc/postfix/generic
postmap hash:/etc/postfix/sasl_passwd hash:/etc/postfix/generic
chmod 600 /etc/postfix/sasl_passwd /etc/postfix/generic
echo " inet_protocols = ipv4

myhostname=pbs.giaroom.com

smtpd_banner = $myhostname ESMTP $mail_name (Debian/GNU)
biff = no
append_dot_mydomain = no
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
mydestination = $myhostname, localhost.$mydomain, localhost
mynetworks = 127.0.0.0/8
inet_interfaces = loopback-only
recipient_delimiter = +
compatibility_level = 2

relayhost = smtp.gmail.com:465
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_security_options =
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_tls_CAfile = /etc/ssl/certs/Entrust_Root_Certification_Authority.pem
smtp_tls_session_cache_database = btree:/var/lib/postfix/smtp_tls_session_cache
smtp_tls_session_cache_timeout = 3600s
smtp_tls_wrappermode = yes
smtp_tls_security_level = encrypt
smtp_generic_maps = hash:/etc/postfix/generic" >/etc/postfix/main.cf

systemctl start postfix
systemctl enable postfix
