#!/bin/bash
# Purpose: Linux Join to Domain

whowhowho="who am i"
log="/var/log/AD_int.log"

## Identify domain
echo -e "Select Domain 1.Domain1 2.Domain2"
while :
do
        read domain
        case $domain in
                1)
                        suffix="domain1.com"
                        ss="domain1"
                        sudoers="domain1\it operation team"
                        sagroup="it operation team"
                        DNS1="ipaddress"
                        DNSNAME1="primary dns server"
                        DNS2="ipaddress"
                        DNSNAME2="secondary dns server"
                        echo "Noted."
                        echo -e "Domain1 Domain has been selected" 2>&1 | tee $log
                        break
                        ;;
                2)
                        suffix="domain2.com"
                        ss="domain2"
                        sudoers="domain2\it operation team"
                        sagroup="it operation team"
                        DNS1="ipaddress"
                        DNSNAME1="primary dns server"
                        DNS2="ipaddress"
                        DNSNAME2="secondary dns server"
                        echo "Noted."
                        echo -e "Domain2 Domain has been selected" 2>&1 | tee $log
                        break
                        ;;
                *)
                        echo "Please try again"
                        ;;

        esac
done

## Update hostname with domain appended

                echo -e "----Updating hostname with domain appended----" 2>&1 | tee -a $log
hostname=$(hostname)
hostnamectl set-hostname $hostname.$suffix
systemctl restart systemd-hostnamed
        echo -e "----Checking hostname update status----" 2>&1 | tee -a $log
systemctl status systemd-hostnamed | grep -A5 -i $hostname 2>&1 | tee -a $log
        if [ $? -eq 0 ]
                then
                echo -e "hostname -- $hostname.$suffix was updated successfully" 2>&1 | tee -a $log
        fi
                echo -e "..\n..\n.." 2>&1 | tee -a $log

## Install the required packages

                echo "----Installing required packages----" 2>&1 | tee -a $log
yum install sssd realmd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation openldap-clients policycoreutils-python -y >>$log 2>&1
                if [ $? -eq 0 ]
                then
                echo -e "Required packages have been successfully installed" 2>&1 | tee -a $log
        fi
                echo -e "..\n..\n.." 2>&1 | tee -a $log

## Update the hosts and resolv.conf files

                echo "----Updating to /etc/hosts file----" 2>&1 | tee -a $log
                echo -e "$DNS1 $DNSNAME1.$suffix $ss\n$DNS2 $DNSNAME2.$suffix $ss" > /etc/hosts
cat /etc/hosts | grep $suffix 2>&1 | tee -a $log
                if [ $? -eq 0 ]
                then
                echo -e "/etc/hosts file have been successfully updated" 2>&1 | tee -a $log
        fi
                echo -e "..\n----Updating to /etc/resolv.conf----" 2>&1 | tee -a $log
                echo -e "search $suffix\nnameserver $DNS1\nnameserver $DNS2" > /etc/resolv.conf
cat /etc/resolv.conf | grep -A3 $suffix >> $log
                if [ $? -eq 0 ]
                then
                echo -e "/etc/resolv.conf file have been successfully updated" 2>&1 | tee -a $log
        fi
                echo -e "..\n..\n.." 2>&1 | tee -a $log

## Join Windows Domain or Integrate with AD using realm command
                echo -e "Joining $ss Domain... ..." 2>&1 | tee -a $log
# ME=$($whowhowho| cut -d' ' -f1)
read -p "Enter adm account to join domain: " account
                echo -e "My username: $account" 2>&1 | tee -a $log
realm join -v -U $account $suffix 2>&1 | tee -a $log || exit 1
                if /sbin/realm list | grep -e "$suffix"
                                then
                                echo -e "Welcome to $suffix Domain"
        else
                echo "Unsuccessful, please type 'realm list' for more information"
        fi
                echo -e "..\n..\n.." 2>&1 | tee -a $log

## Update /etc/sssd/sssd.conf
                echo "----Updating to /etc/sssd/sssd.conf file----" 2>&1 | tee -a $log
                echo "dyndns_update = True" >> /etc/sssd/sssd.conf
sed -i 's/^\(use_fully_qualified_names\ =\).*/\1\ False/' /etc/sssd/sssd.conf
sed -i 's/^\(fallback_homedir\ =\).*/\1\ \/home\/\%u/' /etc/sssd/sssd.conf
echo -e "ad_maximum_machine_account_password_age = 0" >> /etc/sssd/sssd.conf
                echo -e "Results:\n" 2>&1 | tee -a $log
                echo -e "----Checking in sssd.conf----" 2>&1 | tee -a $log
grep -e "use_fully\|fallback\|dyndns_update" /etc/sssd/sssd.conf 2>&1 | tee -a $log
                echo -e "..\n..\n.." 2>&1 | tee -a $log

## Restart SSSD
systemctl restart sssd
                echo -e "----Checking hostname update status----" 2>&1 | tee -a $log
systemctl daemon-reload
                echo -e "----Checking hostname update status----" 2>&1 | tee -a $log
systemctl status sssd | grep -n5 active 2>&1 | tee -a $log
        if [ $? -eq 0 ]
                then
                echo -e "sssd.conf file have been successfully updated" 2>&1 | tee -a $log
        fi
                echo -e "..\n..\n.." 2>&1 | tee -a $log

## Update Sudoers file to add IT Ops Team to run as sudoers
                echo -e "----Adding SA to sudoers list----" 2>&1 | tee -a $log
                echo -e "## Allow domain Ops team to have full privileges\n\"%$sudoers\" ALL=(ALL) ALL" >> /etc/sudoers
                echo -e "----Checking sudoers file----" 2>&1 | tee -a $log
                grep -i "it operation" /etc/sudoers 2>&1 | tee -a $log
                echo -e "..\n..\n.." 2>&1 | tee -a $log

## Deny all AD users the access to Linux and add specific groups only
                echo -e "----Deny All and allow only Ops Groups to realm----" 2>&1 | tee -a $log
realm deny --all
realm permit --groups "$sagroup"
                echo -e "----Checking realm permitted list----" 2>&1 | tee -a $log
                /sbin/realm list | grep 'permitted' 2>&1 | tee -a $log
                echo -e "..\n..\n.." 2>&1 | tee -a $log

## Update ssh config
                echo -e "----Allow Ops Group to SSH----" 2>&1 | tee -a $log
sed -i '/^AllowUsers/d' /etc/ssh/sshd_config
sed -i '/^AllowGroups/d' /etc/ssh/sshd_config
echo -e "AllowGroups root wheel \"$sagroup\"" >> /etc/ssh/sshd_config
                echo -e "----Checking sshd config----" 2>&1 | tee >> $log
grep -e "AllowGroups\|AllowUsers" /etc/ssh/sshd_config 2>&1 | tee >> $log
systemctl restart sshd
systemctl status sshd | grep -n5 active 2>&1 | tee -a $log
                echo -e "..\n..\n.." 2>&1 | tee -a $log

## Revert back hostname with NO domain suffix
                echo -e "Domain Joining should be successful, please remain this session open and do "watch -n5 'systemctl status -l sshd'", open another session and ssh using adm account"
                echo -e "For more details, please view log file @/var/log/AD_int.log"
                echo -e "--------------------------------------------------------------------------" 2>&1 | tee >> $log
## ---END---