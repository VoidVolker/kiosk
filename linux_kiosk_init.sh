#!/bin/bash
echo Installling kiosk mode...
# Kiosk configuration
userName="kiosk"
kioskRunName="kiosk.sh"
kioskRunPath="/home/$userName/$kioskRunName"
kioskAppPath="/home/kiosk/kiosk/app"

# SSH configuration
localPort="5000"
tunnelPort="5001"
server="192.168.1.190"
serverUser="me"
# ssh -N -g -R 192.168.1.190:5555:127.0.0.1:22 me@192.168.1.190
# autossh -f -o TCPKeepAlive=yes -o ServerAliveInterval=300 -o ServerAliveCountMax=3 -N -g -R 192.168.1.190:5555:127.0.0.1:22 me@192.168.1.190
# autossh -f -o TCPKeepAlive=yes -o ServerAliveInterval=300 -o ServerAliveCountMax=3 -N -g -R $server:$serverPort:127.0.0.1:$tunnelPort $serverUser@$server

# Configuring autossh
export AUTOSSH_DEBUG=1
export AUTOSSH_GATETIME=0
export AUTOSSH_PORT=5100

# Scripts configuration
sessionName="kiosk.desktop"
sessionPath="/usr/share/xsessions/$sessionName"
defSesPath="/etc/lightdm/lightdm.conf.d/10-xubuntu.conf"
defSesKey="user-session"
defSesSection="[SeatDefaults]"
# tunnelName="tunnel.sh"
autorunPath="/etc/rc.local"


# Internal variables
kioskRunContent=''
sessionContent=''
# tunnelContent=""

# Adding kiosk user
echo Adding user: $userName
adduser -m $userName

# Installing simplest window manager, autossh and openssh-server
echo Installing window manager...
apt-get install ratpoison autossh openssh-server

# Creating kioskRun sh script
kioskRunContent+='#!/bin/bash\n'
kioskRunContent+='/usr/bin/ratpoison &\n\n'
kioskRunContent+="TERMINAL=`who | awk '{print $2}'`\n\n"
kioskRunContent+='if test -z "$DBUS_SESSION_BUS_ADDRESS" ; then\n'
kioskRunContent+="\x20\x20\x20\x20eval 'dbus-launch --sh-syntax --exit-with-session'\n"
kioskRunContent+='fi\n\n'
kioskRunContent+='dbus-launch /home/kiosk/kiosk/app\n\n'
kioskRunContent+="kill `ps | grep dbus-launch | grep -v grep | awk '{print $1}'`\n"

# Saving script to file
echo Creating $kioskRunPath...
echo -e $kioskRunContent > $kioskRunPath
echo Setting chmod +x
chmod +x $kioskRunPath

# Creating session file
sessionContent+='[Desktop Entry]\n'
sessionContent+='Version=1.0\n'
sessionContent+='Name=Kiosk session\n'
sessionContent+='Comment=Kiosk session\n'
sessionContent+="Exec=$kioskRunPath\n"
sessionContent+='Icon=\n'
sessionContent+='Type=Application\n'

# Saving script to file
echo Creating $sessionPath
echo -e $sessionContent > $sessionPath
# chmod +x $sessionPath

# Settining kiosk as default session
echo Setting key $defSesKey=$userName in file $defSesPath
sed -i "s/\($defSesKey *= *\).*/\1$userName/" $defSesPath
# [SeatDefaults]
# user-session=kiosk

# Configuring ssh-server
echo Configuring local ssh-server to port $localPort
sed -i 's/^#?Port .*/Port $localPort/g' /etc/ssh/sshd_config
sed -i 's/^#?PasswordAuthentication .*/PasswordAuthentication no/g' /etc/ssh/sshd_config

if grep -q -e 'GatewayPorts' /etc/ssh/sshd_config
then
    sed -i 's/^#?GatewayPorts .*/GatewayPorts clientspecified/g' /etc/ssh/sshd_config
else
    echo "GatewayPorts clientspecified" >> /etc/ssh/sshd_config
fi

# Configuring ssh-client
sshCmd="autossh -f -o TCPKeepAlive=yes -o ServerAliveInterval=300 -o ServerAliveCountMax=3 -N -g -R $server:$tunnelPort:127.0.0.1:$localPort $serverUser@$server"

# Autorun configuring
# grep -q -e 'autossh' || sed -i -e "\x24i \$sshCmd" /etc/rc.local
echo Tunnel autorun configuring in file $autorunPath
if grep -q -e 'autossh' $autorunPath
then
    sed -i "s/^autossh .*/$sshCmd/g" $autorunPath
else
    sed -i -e "\$i \\$sshCmd\n" $autorunPath
fi

echo kiosk mode complete
echo "Don't forget:"
echo -- 1. Set for user $userName permissions
echo -- 2. Create key on server with command: ssh-keygen
echo -- 3. Create key on client with command: ssh-keygen
echo -- 4. Add local key to server with command: ssh-copy-id $serverUser@$server
echo -- 5. Add your own key to server and to client(on user PC):
echo     ssh-copy-id $serverUser@$server
echo     ssh-copy-id $userName@client
echo -- 6. On server in /etc/ssh/sshd_config set 'PasswordAuthentication no' and 'GatewayPorts clientspecified'