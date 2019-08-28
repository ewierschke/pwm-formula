ses_deps_install_packages:
  pkg.installed:
    - names:
      - cyrus-sasl-plain
      - postfix
      - wget

get_postfix_config_script:
  cmd.run:
    - name: aws s3 cp s3://{{ salt['environ.get']('CONFIGBUCKETNAME') }}/postfix_conf.sh /usr/local/bin/postfix_conf.sh

change_postfix_config_permissions:
  file.managed:
    - name: /usr/local/bin/postfix_conf.sh
    - mode: 700
    - replace: False

execute_postfix_config_script:
  cmd.run:
    - name: /usr/local/bin/postfix_conf.sh

selinux_java_tolcl_postfix:
  cmd.run:
    - name: setsebool -P nis_enabled 1

start_postfix_service:
  service.running:
    - name: postfix
    - enable: True

get_ses_rotate_script:
  cmd.run:
    - name: wget -O /usr/local/bin/rotatesescredsforiamuser.sh https://raw.githubusercontent.com/ewierschke/secrets_manager_ad_pass/master/rotatesescredsforiamuser.sh

run_ses_rotate_script:
  cmd.run:
    - name: bash /usr/local/bin/rotatesescredsforiamuser.sh -A {{ salt['environ.get']('SNSSUBSCRIPTIONEMAIL') }} -D {{ salt['environ.get']('MAILFROMDNSDOMAINNAME') }} -U {{ salt['environ.get']('pwmSESIAMUSERNAME') }}