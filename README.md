# pwm-formula
Salt formula for deploying PWM

to be used with systemprep

need to add /srv/salt/formulas/pwm-formula to /etc/salt/minion file_roots section and 'service restart salt-minion'

need to append /srv/salt/states/base/top.sls with '    - pwm'

clone this formula to /srv/salt/formulas/
