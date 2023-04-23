# Shell script to join Linux machine into domain

This shell script is tested  with Linux flavors like Centos 7 or Almalinux 8 that are binary-compatible with Red Hat Enterprise Linux (RHEL).

The following will be executed in sequence:

1. Identify domain
2. Update hostname with domain appended
3. Install the required packages
4. Update the hosts and resolv.conf files
5. Join Windows Domain or Integrate with AD using realm command
6. Update /etc/sssd/sssd.conf
7. Restart SSSD
8. Update Sudoers file to add IT Ops Team to run as sudoers
9. Deny all AD users the access to Linux and add specific groups only
10. Update ssh config
11. Revert back hostname with NO domain suffix

Goodluck!
