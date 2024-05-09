
iptables -A INPUT -m state --state INVALID -j DROP

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP

iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

iptables -A INPUT -i lo -j ACCEPT -m comment --comment "Enable Loopback"

iptables -A INPUT -p icmp -j ACCEPT


iptables -A INPUT -p tcp -s 10.0.0.0/8 -m tcp -m multiport --ports 22,8006 -j ACCEPT

iptables -A INPUT -p tcp -s 172.16.0.0/12 -m tcp -m multiport --ports 22,8006 -j ACCEPT

iptables -A INPUT -p tcp -s 192.168.0.0/16 -m tcp -m multiport --ports 22,8006 -j ACCEPT



iptables -A INPUT -p tcp -s lesnoy.mlp.pp.ua -m tcp -m multiport --ports 22,8006 -j ACCEPT -m comment --comment "lesnoy"

iptables -A INPUT -p tcp -s home.mlp.pp.ua -m tcp -m multiport --ports 22,8006 -j ACCEPT -m comment --comment "Home"

iptables -A INPUT -p tcp -s unac.mlp.pp.ua -m tcp -m multiport --ports 22,8006 -j ACCEPT -m comment --comment "unac"

iptables -A INPUT -p tcp -s lesnoy.mlp.pp.ua -m tcp -m multiport --ports 22,8006 -j ACCEPT -m comment --comment "lesnoy"

iptables -A INPUT -p tcp -s bku.mlp.pp.ua -m tcp -m multiport --ports 22,8006 -j ACCEPT -m comment --comment "BKU"

iptables -A INPUT -p tcp -s oracle.mlp.pp.ua -m tcp -m multiport --ports 22,8006 -j ACCEPT -m comment --comment "oracle"

iptables -A INPUT -p tcp -s oracle2.mlp.pp.ua -m tcp -m multiport --ports 22,8006 -j ACCEPT -m comment --comment "oracle2"


iptables -P INPUT DROP


ip6tables -A INPUT -m conntrack --ctstate INVALID -j DROP

ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

ip6tables -A INPUT -i lo -j ACCEPT -m comment --comment "Enable Loopback"

ip6tables -A INPUT -p tcp -s 2a03:7380:254:200::/64 -m tcp --dport 22 -j ACCEPT -m comment --comment "Lesnoy"

ip6tables -A INPUT -p tcp -s 2a01:4f9:2a:31ae::/64 -m tcp --dport 22 -j ACCEPT -m comment --comment "giaroom"

ip6tables -A INPUT -p tcp -s 2a01:4f9:2a:30d4::/64 -m tcp --dport 22 -j ACCEPT -m comment --comment "Eddy"

ip6tables -P INPUT DROP




apt update
apt install iptables-persistent -y
service netfilter-persistent save