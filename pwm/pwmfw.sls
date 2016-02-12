inputacceptpolicy:
  iptables.set_policy:
    - chain: INPUT
    - policy: ACCEPT

flushinput:
  iptables.flush:
    - chain: INPUT

loopbackall:
  iptables.append:
    - family: ipv4
    - chain: INPUT
    - jump: ACCEPT
    - comment: "Allow inbound on loopback for app to postfix mailing"
    - in-interface: lo

allconnstate:
  iptables.append:
    - chain: INPUT
    - match: state
    - connstate: RELATED,ESTABLISHED
    - jump: ACCEPT

allowsshall:
  iptables.append:
    - chain: INPUT
    - match: state
    - connstate: NEW
    - proto: tcp
    - dport: 22
    - jump: ACCEPT

dest80all:
  iptables.append:
    - family: ipv4
    - chain: INPUT
    - jump: ACCEPT
    - comment: "Allow HTTP"
    - dport: 80
    - proto: tcp

dest8080all:
  iptables.append:
    - family: ipv4
    - chain: INPUT
    - jump: ACCEPT
    - comment: "Allow access to Tomcat Mgmt 8080"
    - dport: 8080
    - proto: tcp

inputdroppolicy:
  iptables.set_policy:
    - chain: INPUT
    - policy: DROP
    - save: True
