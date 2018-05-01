#!/bin/bash
#
# Description:
#    This script is intended to manage the lifecycle of user accounts imported 
#    from IAM.
#    If users from the required parameter IAM group don't exist on the system, 
#    the script creates them.  If users exist on the instance from a previous 
#    script run but do not exist in the defined IAM group, the script deletes 
#    them.
#    The use of an attached instance role with proper policy to query the IAM 
#    group members is required.
#    This script is intended to be paired with the use of an SSHd
#    AuthorizedKeysCommand setting to enable SSH key access.
#    This script configures the created users to be able to run only specific 
#    sudo commands required for ServiceNow Discovery
#    ref - https://docs.servicenow.com/bundle/kingston-it-operations-management/page/product/discovery/reference/r_SSHCredentialsForm.html#r_SSHCredentialsForm
#
#################################################################
__ScriptName="discousermgmt.sh"

log()
{
    logger -i -t "${__ScriptName}" -s -- "$1" 2> /dev/console
    echo "$1"
}  # ----------  end of function log  ----------


die()
{
    [ -n "$1" ] && log "$1"
    log "${__ScriptName} script failed"'!'
    exit 1
}  # ----------  end of function die  ----------

usage()
{
    cat << EOT
  Usage:  ${__ScriptName} [options]

  Note:
  If 

  Options:
  -h  Display this message.
  -G  The IAM group name from which to generate local users.
EOT
}  # ----------  end of function usage  ----------

# Parse command-line parameters
while getopts :hG: opt
do
    case "${opt}" in
        h)
            usage
            exit 0
            ;;
        G)
            GROUP_NAME="${OPTARG}"
            ;;
        \?)
            usage
            echo "ERROR: unknown parameter \"$OPTARG\""
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

# Validate parameters
if [ -z "${GROUP_NAME}" ]
then
    die "GROUP_NAME was not provided"
fi

# Begin main script
# If usermgmt wasn't previously executed to create discolastimportsshusers.log, create blank file for future comparision
if [ -e "/usr/local/bin/discolastimportsshusers.log" ]
   then echo "discolastimportsshusers.log exists" > /dev/null
else
   touch /usr/local/bin/discolastimportsshusers.log | echo "" > /usr/local/bin/discolastimportsshusers.log
fi
#query IAM and create file of current members of group
aws iam get-group --group-name "${GROUP_NAME}" --query "Users[].[UserName]" --output text > /usr/local/bin/discoimportsshusers.log 2>&1
if [ $? -eq 255 ]; then
  log "${__ScriptName} aws cli failure - possible issue; EC2 Instance role not setup with proper credentials or policy"
fi
#create sorted files for use with comm
sort < /usr/local/bin/discolastimportsshusers.log > /usr/local/bin/discolastimportsshusers.sorted.log
sort < /usr/local/bin/discoimportsshusers.log > /usr/local/bin/discoimportsshusers.sorted.log
#create list of users to be imported that weren't already imported
#create file sshuserstocreate from list of items in discolastimportsshusers that aren't in discolastimportsshusers
comm -23 /usr/local/bin/discoimportsshusers.sorted.log /usr/local/bin/discolastimportsshusers.sorted.log > /usr/local/bin/sshuserstocreate.log
#create list of users to be deleted that no longer exist in IAM
#create file sshuserstodelete from list of items in discolastimportsshusers that aren't in discolastimportsshusers
comm -13 /usr/local/bin/discoimportsshusers.sorted.log /usr/local/bin/discolastimportsshusers.sorted.log > /usr/local/bin/sshuserstodelete.log
#create new users with locked password for ssh and add to sudoers.d folder
while read User
do
  if id -u "$User" > /dev/null 2>&1; then
    echo "$User exists"
  else
    /usr/sbin/adduser "$User"
    passwd -l "$User"
    if [ $? -ne 3 ]; then
    (
      printf "%s ALL=(root) NOPASSWD: /usr/sbin/dmidecode\n" "$User"
      printf "%s ALL=(root) NOPASSWD: /usr/sbin/lsof\n" "$User"
      printf "%s ALL=(root) NOPASSWD: /usr/sbin/fdisk -l\n" "$User"
      printf "%s ALL=(root) NOPASSWD: /usr/sbin/dmsetup table *\n" "$User"
      printf "%s ALL=(root) NOPASSWD: /usr/sbin/dmsetup ls\n" "$User"
      printf "%s ALL=(root) NOPASSWD: /usr/sbin/multipath -ll\n" "$User"
    ) > "/etc/sudoers.d/$User"
      log "User $User created by ${__ScriptName}"
    fi
  fi
done < /usr/local/bin/sshuserstocreate.log
#delete users not in IAM group
while read User
do
    /usr/sbin/userdel -r "$User"
    if [ $? -ne 6 ]; then
      rm /etc/suoders.d/"$User"
      log "User $User deleted by ${__ScriptName}"
    fi
done < /usr/local/bin/sshuserstodelete.log
shred -u /usr/local/bin/sshuserstodelete.log
shred -u /usr/local/bin/sshuserstocreate.log
shred -u /usr/local/bin/discoimportsshusers.sorted.log
shred -u /usr/local/bin/discolastimportsshusers.sorted.log
#get ready for next run
#move current discolastimportsshusers list to discolastimportsshusers list
mv /usr/local/bin/discoimportsshusers.log /usr/local/bin/discolastimportsshusers.log
chmod 600 /usr/local/bin/discolastimportsshusers.log
