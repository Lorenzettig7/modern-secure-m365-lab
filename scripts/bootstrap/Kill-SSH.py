#!/bin/bash
set -e
echo "$(date) - Kill SSH script ran" >> /var/log/intune-kill-ssh.log
# Turn off "Remote Login" (SSH)
 /usr/sbin/systemsetup -f -setremotelogin off || true

# Belt + suspenders: disable sshd launch daemon
/bin/launchctl disable system/com.openssh.sshd 2>/dev/null || true
/bin/launchctl bootout system /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true

exit 0
