#!/bin/bash
# Forked from https://github.com/blacklanternsecurity/kali-setup-script/blob/master/kali-setup-script.sh

usage()
{
    cat <<EOF
Usage: ${0##*/} [option]
  Options:
    --i3            Set up i3 as the default window manager
    --remove-i3     Set window manager back to XFCE defaults
    --help          Display this message

EOF
exit 0
}

# parse arguments
while :
do
    case $1 in
        i3|-i3|--i3)
            install_i3=true;
            ;;
        remove-i3|-remove-i3|--remove-i3)
            remove_i3=true;
            ;;
        -h|--help|help)
            usage
            ;;
        *)
            break
    esac
    shift
done

# make sure we're root
if [ "$HOME" != "/root" ]
then
    printf "Please run while logged in as root\n"
    exit 1
fi

# fix bashrc
cp /root/.bashrc /root/.bashrc.bak
cp "/home/$(fgrep 1000:1000 /etc/passwd | cut -d: -f1)/.bashrc" /root/.bashrc
. /root/.bashrc

# enable command aliasing
shopt -s expand_aliases

# skip prompts in apt
#export DEBIAN_FRONTEND=noninteractive
#alias apt='yes "" | apt -y -o Dpkg::Options::="--force-confdef" -y'
#apt -y update

# make sure Downloads folder exists
mkdir -p ~/Downloads 2>/dev/null

# if we're not on a headless system
if [ -n "$DISPLAY" ]
then


    printf '\n============================================================\n'
    printf '[+] Enabling Tap-to-click\n'
    printf '============================================================\n\n'
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
    xfconf-query -c pointers -p /SynPS2_Synaptics_TouchPad/Properties/libinput_Tapping_Enabled -n -t int -s 1 --create
    xfconf-query -c pointers -p /SynPS2_Synaptics_TouchPad/Properties/Synaptics_Tap_Action -n -s 0 -s 0 -s 0 -s 0 -s 1 -s 3 -s 2 -t int -t int -t int -t int -t int -t int -t int --create


    printf '\n============================================================\n'
    printf '[+] Disabling Auto-lock, Sleep on AC\n'
    printf '============================================================\n\n'
    # disable session idle
    gsettings set org.gnome.desktop.session idle-delay 0
    # disable sleep when on AC power
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
    # disable screen timeout on AC
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0 --create --type int
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-off -s 0 --create --type int
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-sleep -s 0 --create --type int
    # disable sleep when on AC
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/inactivity-on-ac -s 14 --create --type int
    # hibernate when power is critical
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/critical-power-action -s 2 --create --type int

fi



# install pip
cd /root/Downloads
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py


printf '\n============================================================\n'
printf '[+] Disabling LL-MNR\n'
printf '============================================================\n\n'
echo '[Match]
name=*

[Network]
LLMNR=no' > /etc/systemd/network/90-disable-llmnr.network


printf '\n============================================================\n'
printf '[+] Removing gnome-software\n'
printf '============================================================\n\n'
killall gnome-software
while true
do
    pgrep gnome-software &>/dev/null || break
    sleep .5
done
apt -y remove gnome-software


printf '\n============================================================\n'
printf '[+] Installing:\n'
printf '     - wireless drivers\n'
# printf '     - golang & environment\n'
printf '     - docker\n'
printf '     - powershell\n'
printf '     - terminator\n'
printf '     - pip & pipenv\n'
printf '     - patator\n'
#printf '     - vncsnapshot\n'
printf '     - zmap\n'
printf '     - htop\n'
printf '     - mosh\n'
printf '     - tmux\n'
printf '     - NFS server\n'
printf '     - DNS Server\n'
printf '     - hcxtools (hashcat)\n'
printf '============================================================\n\n'
apt -y install \
    realtek-rtl88xxau-dkms \
    golang \
    docker.io \
    powershell \
    terminator \
    python3-dev \
    python3-pip \
    patator \
    net-tools \
#    vncsnapshot \
    zmap \
    htop \
    mosh \
    tmux \
    nfs-kernel-server \
    dnsmasq \
    hcxtools \
    mosh \
    vim
python2 -m pip install pipenv
python3 -m pip install pipenv
apt -y remove mitmproxy
python3 -m pip install mitmproxy

# default tmux config
cat <<EOF > "$HOME/.tmux.conf"
set -g mouse on
set -g history-limit 50000

# List of plugins
set -g @plugin 'tmux-plugins/tmux-logging'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
EOF

# enable and start docker
systemctl stop docker &>/dev/null
#echo '{"bip":"172.16.199.1/24"}' > /etc/docker/daemon.json
#systemctl enable docker --now

# initialize mitmproxy cert
mitmproxy &>/dev/null &
sleep 5
killall mitmproxy
# trust certificate
cp ~/.mitmproxy/mitmproxy-ca-cert.cer /usr/local/share/ca-certificates/mitmproxy-ca-cert.crt
update-ca-certificates

# mkdir -p /root/.go
# gopath_exp='export GOPATH="$HOME/.go"'
# path_exp='export PATH="/usr/local/go/bin:$GOPATH/bin:$PATH"'
# sed -i '/export GOPATH=.*/c\' ~/.profile
# sed -i '/export PATH=.*GOPATH.*/c\' ~/.profile
# echo $gopath_exp | tee -a "$HOME/.profile"
# grep -q -F "$path_exp" "$HOME/.profile" || echo $path_exp | tee -a "$HOME/.profile"
# . "$HOME/.profile"

# enable NFS server (without any shares)
# systemctl enable nfs-server
# systemctl start nfs-server
# fgrep '1.1.1.1/255.255.255.255(rw,sync,all_squash,anongid=0,anonuid=0)' /etc/exports &>/dev/null || echo '#/root        1.1.1.1/255.255.255.255(rw,sync,all_squash,anongid=0,anonuid=0)' >> /etc/exports
# exportfs -a

# example NetworkManager.conf line for blacklist interfaces
# fgrep 'unmanaged-devices' &>/dev/null /etc/NetworkManager/NetworkManager.conf || echo -e '[keyfile]\nunmanaged-devices=mac:de:ad:be:ef:de:ad' >> /etc/NetworkManager/NetworkManager.conf


printf '\n============================================================\n'
printf '[+] Updating System\n'
printf '============================================================\n\n'
apt -y update
apt -y upgrade

# install hyper-v Enhanced Session Mode
if [ -f /var/run/reboot-required ]; then
    echo "A reboot is required in order to proceed with the install." >&2
    echo "Please reboot and re-run this script to finish the install." >&2
    exit 1
fi

printf '\n============================================================\n'
printf '[+] Installing XRDP\n'
printf '============================================================\n\n'
apt -y install xrdp

printf '\n============================================================\n'
printf '[+] Configuring XRDP\n'
printf '============================================================\n\n'
systemctl enable xrdp
systemctl enable xrdp-sesman

# Configure the installed XRDP ini files.
# use vsock transport.
# sed -i_orig -e 's/use_vsock=false/use_vsock=true/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
# use rdp security.
sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
# remove encryption validation.
sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
# disable bitmap compression since its local its much faster
sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini
sed -n -e 's/max_bpp=32/max_bpp=24/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/X11DisplayOffset=10/X11DisplayOffset=0/g' /etc/xrdp/sesman.ini
# rename the redirected drives to 'shared-drives'
sed -i_orig -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini

# Change the allowed_users
echo "allowed_users=anybody" > /etc/X11/Xwrapper.config


#Ensure hv_sock gets loaded
if [ ! -e /etc/modules-load.d/hv_sock.conf ]; then
	echo "hv_sock" > /etc/modules-load.d/hv_sock.conf
fi

# Configure the policy xrdp session
cat > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla <<EOF
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

###############################################################################
# .xinitrc has to be modified manually.
#

echo "exec startxfce4" > ~/.xinitrc
#echo "You will have to configure .xinitrc to start your windows manager, see https://wiki.archlinux.org/index.php/Xinit"
echo "Reboot your machine to begin using XRDP."




printf '\n============================================================\n'
printf '[+] Installing Bettercap\n'
printf '============================================================\n\n'
apt -y install libnetfilter-queue-dev libpcap-dev libusb-1.0-0-dev
go get -v github.com/bettercap/bettercap


printf '\n============================================================\n'
printf '[+] Installing EapHammer\n'
printf '============================================================\n\n'
cd ~/Downloads
git clone https://github.com/s0lst1c3/eaphammer.git
cd eaphammer
apt -y install $(grep -vE "^\s*#" kali-dependencies.txt  | tr "\n" " ")
chmod +x kali-setup
# remove prompts from setup script
sed -i 's/.*input.*update your package list.*/    if False:/g' kali-setup
sed -i 's/.*input.*upgrade your installed packages.*/    if False:/g' kali-setup
sed -i 's/.*apt.* install.*//g' kali-setup
./kali-setup
ln -s ~/Downloads/eaphammer/eaphammer /usr/local/bin/eaphammer


# printf '\n============================================================\n'
# printf '[+] Installing Gowitness\n'
# printf '============================================================\n\n'
# go get -v github.com/sensepost/gowitness


printf '\n============================================================\n'
printf '[+] Installing MAN-SPIDER\n'
printf '============================================================\n\n'
cd ~/Downloads
git clone https://github.com/blacklanternsecurity/MANSPIDER
cd MANSPIDER && python3 -m pipenv install -r requirements.txt


printf '\n============================================================\n'
printf '[+] Installing bloodhound.py\n'
printf '============================================================\n\n'
pip install bloodhound


printf '\n============================================================\n'
printf '[+] Installing PCredz\n'
printf '============================================================\n\n'
apt -y remove python-pypcap
apt -y install python-libpcap
cd ~/Downloads
git clone https://github.com/lgandx/PCredz.git
ln -s ~/Downloads/PCredz/Pcredz /usr/local/bin/pcredz


printf '\n============================================================\n'
printf '[+] Installing EavesARP\n'
printf '============================================================\n\n'
cd ~/Downloads
git clone https://github.com/mmatoscom/eavesarp
cd eavesarp && python3 -m pip install -r requirements.txt
cd && ln -s ~/Downloads/eavesarp/eavesarp.py /usr/local/bin/eavesarp


printf '\n============================================================\n'
printf '[+] Installing CrackMapExec\n'
printf '============================================================\n\n'
cme_dir="$(ls -d /root/.local/share/virtualenvs/* | grep CrackMapExec | head -n 1)"
if [[ ! -z "$cme_dir" ]]; then rm -r "${cme_dir}.bak"; mv "${cme_dir}" "${cme_dir}.bak"; fi
apt -y install libssl-dev libffi-dev python-dev build-essential
cd ~/Downloads
git clone --recursive https://github.com/byt3bl33d3r/CrackMapExec
cd CrackMapExec && python3 -m pipenv install
python3 -m pipenv run python setup.py install
ln -s ~/.local/share/virtualenvs/$(ls /root/.local/share/virtualenvs | grep CrackMapExec | head -n 1)/bin/cme ~/usr/local/bin/cme
apt -y install crackmapexec


printf '\n============================================================\n'
printf '[+] Installing Impacket\n'
printf '============================================================\n\n'
cd ~/Downloads
git clone https://github.com/CoreSecurity/impacket.git
cd impacket && python3 -m pipenv install
python3 -m pipenv run python setup.py install


printf '\n============================================================\n'
printf '[+] Enabling bash session logging\n'
printf '============================================================\n\n'

apt -y install tmux-plugin-manager
mkdir -p "$HOME/.tmux/plugins" 2>/dev/null
export XDG_CONFIG_HOME="$HOME"
export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
/usr/share/tmux-plugin-manager/scripts/install_plugins.sh
mkdir -p "$HOME/Logs" 2>/dev/null

grep -q 'TMUX_LOGGING' "/etc/profile" || echo '
logdir="$HOME/Logs"
if [ ! -d $logdir ]; then
    mkdir $logdir
fi
#gzip -q $logdir/*.log &>/dev/null
export XDG_CONFIG_HOME="$HOME"
export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
if [[ ! -z "$TMUX" && -z "$TMUX_LOGGING" ]]; then
    logfile="$logdir/tmux_$(date -u +%F_%H_%M_%S)_UTC.$$.log"
    "$TMUX_PLUGIN_MANAGER_PATH/tmux-logging/scripts/start_logging.sh" "$logfile"
    export TMUX_LOGGING="$logfile"
fi' >> "/etc/profile"

normal_log_script='
logdir="$HOME/Logs"
if [ ! -d $logdir ]; then
    mkdir $logdir
fi
if [[ -z "$NORMAL_LOGGING" && ! -z "$PS1" && -z "$TMUX" ]]; then
    logfile="$logdir/$(date -u +%F_%H_%M_%S)_UTC.$$.log"
    export NORMAL_LOGGING="$logfile"
    script -f -q "$logfile"
    exit
fi'

grep -q 'NORMAL_LOGGING' "$HOME/.bashrc" || echo "$normal_log_script" >> "$HOME/.bashrc"
grep -q 'NORMAL_LOGGING' "$HOME/.zshrc" || echo "$normal_log_script" >> "$HOME/.zshrc"


printf '\n============================================================\n'
printf '[+] Initializing Metasploit Database\n'
printf '============================================================\n\n'
systemctl start postgresql
systemctl enable postgresql
msfdb init


printf '\n============================================================\n'
printf '[+] Unzipping RockYou\n'
printf '============================================================\n\n'
gunzip /usr/share/wordlists/rockyou.txt.gz 2>/dev/null
ln -s /usr/share/wordlists ~/Downloads/wordlists 2>/dev/null


if [ -n "$remove_i3" ]
then

    printf '\n============================================================\n'
    printf '[+] Removing i3\n'
    printf '============================================================\n\n'
    rm ~/.config/autostart/i3.desktop
    rm ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
    rm -r ~/.cache/sessions
fi


if [ -n "$install_i3" ]
then

    printf '\n============================================================\n'
    printf '[+] Installing i3\n'
    printf '============================================================\n\n'
    # install dependencies
    apt -y install i3 j4-dmenu-desktop fonts-hack feh
    # make sure .config directory exists
    mkdir -p /root/.config
    # make startup script
    echo '#!/bin/bash
xrandr --output eDP-1 --mode 1920x1080
sleep 1
feh --bg-scale /usr/share/wallpapers/wallpapers/bls_wallpaper.png
' > /root/.config/i3_startup.sh

    # set up config
    grep '### KALI SETUP SCRIPT ###' /etc/i3/config.keycodes || echo '
### KALI SETUP SCRIPT ###
# win+L lock screen
# bindsym $sup+l exec i3lock -i /usr/share/wallpapers/wallpapers/bls_wallpaper.png
# win+E file explorer
# bindsym $sup+e exec thunar
# resolution / wallpaper
exec_always --no-startup-id bash "/root/.config/i3_startup.sh"

# BLS theme
# class             border  background  text        indicator   child_border
client.focused      #666666 #666666     #FFFFFF     #FFFFFF     #666666
' >> /etc/i3/config.keycodes

    # gnome terminal
    sed -i 's/^bindcode $mod+36 exec.*/bindcode $mod+36 exec gnome-terminal/' /etc/i3/config.keycodes
    # improved dmenu
    sed -i 's/.*bindcode $mod+40 exec.*/bindcode $mod+40 exec --no-startup-id j4-dmenu-desktop/g' /etc/i3/config.keycodes
    # mod+shift+e logs out of gnome
    sed -i 's/.*bindcode $mod+Shift+26 exec.*/bindcode $mod+Shift+26 exec xfce4-session-logout/g' /etc/i3/config.keycodes
    # hack font
    sed -i 's/^font pango:.*/font pango:hack 11/' /etc/i3/config.keycodes
    # focus child
    sed -i 's/bindcode $mod+39 layout stacking/#bindcode $mod+39 layout stacking/g' /etc/i3/config.keycodes
    sed -i 's/.*bindsym $mod+d focus child.*/bindcode $mod+39 focus child/g' /etc/i3/config.keycodes

    # get rid of saved sessions
    rm -r /root/.cache/sessions/*

    # hide xfwm
    sed -i '/export GOPATH=.*/c\' /usr/share/applications/xfce-wm-settings.desktop
    echo 'Hidden=true' >> /usr/share/applications/xfce-wm-settings.desktop

    # create i3 autostart file
    mkdir -p /root/.config/autostart 2>/dev/null
    cat <<EOF > /root/.config/autostart/i3.desktop
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=i3
Comment=i3
Exec=i3
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false
EOF

    # create XFCE session
    mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null
    cat <<EOF > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-session" version="1.0">
  <property name="general" type="empty">
    <property name="FailsafeSessionName" type="string" value="Failsafe"/>
    <property name="LockCommand" type="string" value=""/>
  </property>
  <property name="sessions" type="empty">
    <property name="Failsafe" type="empty">
      <property name="IsFailsafe" type="bool" value="true"/>
      <property name="Count" type="int" value="1"/>
      <property name="Client0_Command" type="array">
        <value type="string" value="xfsettingsd"/>
      </property>
      <property name="Client0_PerScreen" type="bool" value="false"/>
    </property>
  </property>
</channel>
EOF

fi


# if we're not on a headless system
if [ -n "$DISPLAY" ]
then

    printf '\n============================================================\n'
    printf '[+] Installing:\n'
    printf '     - gnome-screenshot\n'
    printf '     - LibreOffice\n'
    printf '     - Remmina\n'
    printf '     - file explorer SMB capability\n'
    printf '============================================================\n\n'
    apt -y install \
        gnome-screenshot \
        libreoffice \
        remmina \
        gvfs-backends # smb in file explorer

    printf '\n============================================================\n'
    printf '[+] Installing Bloodhound\n'
    printf '============================================================\n\n'
    # uninstall old version
    apt -y remove bloodhound
    rm -rf /opt/BloodHound-linux-x64 &>/dev/null

    # download latest bloodhound release from github
    release_url="https://github.com/$(curl -s https://github.com/BloodHoundAD/BloodHound/releases | egrep -o '/BloodHoundAD/BloodHound/releases/download/.{1,10}/BloodHound-linux-x64.zip' | head -n 1)"
    cd /opt
    wget "$release_url"
    unzip -o 'BloodHound-linux-x64.zip'
    rm 'BloodHound-linux-x64.zip'

    # fix white screen issue
    echo -e '#!/bin/bash\n/opt/BloodHound-linux-x64/BloodHound --no-sandbox $@' > /usr/local/bin/bloodhound
    chmod +x /usr/local/bin/bloodhound

    # install Neo4J
    wget -O - https://debian.neo4j.org/neotechnology.gpg.key | apt-key add -
    echo 'deb https://debian.neo4j.org/repo stable/' > /etc/apt/sources.list.d/neo4j.list
    apt -y update
    apt -y install neo4j

    # increase open file limit
    apt -y install neo4j gconf-service gconf2-common libgconf-2-4
    mkdir -p /usr/share/neo4j/logs /usr/share/neo4j/run
    grep '^root   soft    nofile' /etc/security/limits.conf || echo 'root   soft    nofile  500000
    root   hard    nofile  600000' >> /etc/security/limits.conf
    grep 'NEO4J_ULIMIT_NOFILE=60000' /etc/default/neo4j 2>/dev/null || echo 'NEO4J_ULIMIT_NOFILE=60000' >> /etc/default/neo4j
    grep 'fs.file-max' /etc/sysctl.conf 2>/dev/null || echo 'fs.file-max=500000' >> /etc/sysctl.conf
    sysctl -p
    neo4j start

    # install cypheroth, which automates bloodhound queries & outputs to CSV
    cd ~/Downloads
    git clone https://github.com/seajaysec/cypheroth
    ln -s ~/Downloads/cypheroth/cypheroth.sh /usr/local/bin/cypheroth


    printf '\n============================================================\n'
    printf '[+] Installing Firefox\n'
    printf '============================================================\n\n'
    if [[ ! -f /usr/share/applications/firefox.desktop ]]
    then
        wget -O /tmp/firefox.tar.bz2 'https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US'
        cd /opt
        tar -xvjf /tmp/firefox.tar.bz2
        if [[ -f /usr/bin/firefox ]]; then mv /usr/bin/firefox /usr/bin/firefox.bak; fi
        ln -s /opt/firefox/firefox /usr/bin/firefox
        rm /tmp/firefox.tar.bz2

        cat <<EOF > /usr/share/applications/firefox.desktop
[Desktop Entry]
Name=Firefox
Comment=Browse the World Wide Web
GenericName=Web Browser
X-GNOME-FullName=Firefox Web Browser
Exec=/opt/firefox/firefox %u
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=firefox-esr
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;
StartupWMClass=Firefox-esr
StartupNotify=true
EOF
fi


    printf '\n============================================================\n'
    printf '[+] Installing Chromium\n'
    printf '============================================================\n\n'
    apt -y install chromium
    sed -i 's#Exec=/usr/bin/chromium %U#Exec=/usr/bin/chromium --no-sandbox %U#g' /usr/share/applications/chromium.desktop


    printf '\n============================================================\n'
    printf '[+] Updating WPScan
    printf '============================================================\n\n'
    wpscan --update

    printf '\n============================================================\n'
    printf '[+] Get Useful red team scripts'
    printf '============================================================\n\n'
	# winpeas
	
	# linpeas
	
	# shellter
	apt -y install shellter
	apt -y install wine

	# Empire
	apt -y install powershell-empire

    printf '\n============================================================\n'
    printf '[+] Cleaning Up\n'
    printf '============================================================\n\n'
    updatedb
    rmdir ~/Music ~/Public ~/Videos ~/Templates ~/Desktop &>/dev/null
    gsettings set org.gnome.shell favorite-apps "['firefox.desktop', 'org.gnome.Terminal.desktop', 'terminator.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Screenshot.desktop', 'sublime_text.desktop', 'boostnote.desktop']"

fi


printf '\n============================================================\n'
printf "[+] Done. Don't forget to reboot! :)\n"
printf "[+] You may also want to install:\n"
printf '     - BurpSuite Pro\n'
printf '     - Firefox Add-Ons\n'
printf '============================================================\n\n'
