# This is currently intended for ec2 hosts that come with sth like ip-10-10-0-123 for a hostname.
# To match the hostname with the entries created by the hostsfile state, also execute this state.

{%- set fqdn = grains['fqdn'] %}
{%- set localip = grains['ipv4'] %}
{%- if grains['os_family'] == 'RedHat' %}

etc-sysconfig-network:
  cmd.run:
    - name: echo -e "NETWORKING=yes\nHOSTNAME={{ fqdn }}\n" > /etc/sysconfig/network
    - unless: test -f /etc/sysconfig/network
  file.replace:
    - name: /etc/sysconfig/network
    - pattern: HOSTNAME=localhost.localdomain
    - repl: HOSTNAME={{ fqdn }}

{% endif %}
{%- if grains['os_family'] == 'Suse' %}
/etc/HOSTNAME:
  file.managed:
    - contents: {{ fqdn }}
    - backup: false
{% else %}
/etc/hostname:
  file.managed:
    - contents: {{ fqdn }}
    - backup: false
hosts-entry:
  host.present:
    - ip: {{ localip }}
    - names:
      - {{ fqdn }}

{% endif %}
set-fqdn:
  cmd.run:
    {% if grains["init"] == "systemd" %}
    - name: hostnamectl set-hostname {{ fqdn }}
    {% else %}
    - name: hostname {{ fqdn }}
    {% endif %}
    - unless: test "{{ fqdn }}" = "$(hostname)"

