#!/bin/bash
#
BASEDIR=$(dirname $0)
PROJECT_PATH=$(cd $BASEDIR; pwd)
cd
. /lib/lsb/init-functions

sudo rm -r /usr/local/minitower_kit
sudo mkdir /usr/local/minitower_kit || log_warning_msg "Can't make dir /usr/local/minitower_kit" 
sudo cp ${PROJECT_PATH}/backlight_server.py /usr/local/minitower_kit/ 

sudo apt update
sudo apt upgrade -y
sudo usermod -a -G gpio,i2c pi && log_action_msg "grant privilledges to user pi" || log_warning_msg "Grant privilledges failed!" 

# Enable i2c function on raspberry pi.
log_action_msg "Enable i2c on Raspberry Pi "
sudo sed -i '/dtparam=i2c_arm*/d' /boot/config.txt 
sudo sed -i '$a\dtparam=i2c_arm=on' /boot/config.txt 

if [ $? -eq 0 ]; then
   log_action_msg "i2c has been setting up successfully"
fi

cd /usr/local/ 
if [ ! -d luma.examples ]; then
    sudo git clone https://github.com/rm-hull/luma.examples.git || log_warning_msg "Could not download repository from github, please check the internet connection..." 
fi

sudo cp ${PROJECT_PATH}/sysinfo.py /usr/local/luma.examples/examples/ 

cd /usr/local/luma.examples/ && sudo -H pip3 install -e . && log_action_msg "Install dependencies packages successfully..." || log_warning_msg "Cound not access github repository, please check the internet connections!!!" 
#sudo python /usr/local/luma.examples/examples/invaders.py &

log_action_msg "Install libs for backlight (neopixel) ..." 
sudo pip3 install rpi_ws281x adafruit-circuitpython-neopixel
sudo python3 -m pip install --force-reinstall adafruit-blinka

log_action_msg "Minitower Service configuration started..." 

# oled screen display service.
oled_svc="minitower_oled"
oled_svc_file="/usr/lib/systemd/system/${oled_svc}.service"
sudo rm -f ${oled_svc_file}
sudo sh -c "echo \"[Unit]\" > ${oled_svc_file}"
sudo sh -c "echo \"Description=\"Minitower Service OLED\"\" >> ${oled_svc_file}"
sudo sh -c "echo \"DefaultDependencies=no\" >> ${oled_svc_file}"
sudo sh -c "echo \"StartLimitIntervalSec=60\" >> ${oled_svc_file}"
sudo sh -c "echo \"StartLimitBurst=5\" >> ${oled_svc_file}"
sudo sh -c "echo \"[Service]\" >> ${oled_svc_file}"
sudo sh -c "echo \"RootDirectory=/\" >> ${oled_svc_file}"
sudo sh -c "echo \"User=root\" >> ${oled_svc_file}"
sudo sh -c "echo \"Type=forking\" >> ${oled_svc_file}"
sudo sh -c "echo \"KillMode=control-group\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"ExecStart=/bin/bash -c '/usr/bin/python3 /usr/local/luma.examples/examples/sysinfo.py &'\" >> ${oled_svc_file}"
sudo sh -c "echo \"RemainAfterExit=yes\" >> ${oled_svc_file}"
sudo sh -c "echo \"Restart=always\" >> ${oled_svc_file}"
sudo sh -c "echo \"RestartSec=30\" >> ${oled_svc_file}"
sudo sh -c "echo \"[Install]\" >> ${oled_svc_file}"
sudo sh -c "echo \"WantedBy=multi-user.target\" >> ${oled_svc_file}"

sudo chown root:root ${oled_svc_file}
sudo chmod 644 ${oled_svc_file}

log_action_msg "Minitower Service Load OLED module" 
sudo systemctl daemon-reload
sudo systemctl enable ${oled_svc}.service
sudo systemctl restart ${oled_svc}.service 

# mood backlight service.
moodlight_svc="minitower_backlight"
moodlight_svc_file="/lib/systemd/system/${moodlight_svc}.service"
sudo rm -f ${moodlight_svc_file}
sudo sh -c "echo \"[Unit]\" > ${moodlight_svc_file}"
sudo sh -c "echo \"Description='Minitower backlight server'\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"DefaultDependencies=no\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"StartLimitIntervalSec=60\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"StartLimitBurst=5\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"After=multi-user.target\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"After=network.target\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"[Service]\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"RootDirectory=/\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"User=root\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"Type=idle\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"KillMode=control-group\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"ExecStart=/bin/bash -c 'sudo /usr/bin/python3 /usr/local/minitower_kit/backlight_server.py &'\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"RemainAfterExit=yes\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"Restart=always\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"RestartSec=30\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"[Install]\" >> ${moodlight_svc_file}"
sudo sh -c "echo \"WantedBy=multi-user.target\" >> ${moodlight_svc_file}"

sudo chown root:root ${moodlight_svc_file}
sudo chmod 644 ${moodlight_svc_file}

log_action_msg "Minitower Service backlight load module" 
sudo systemctl daemon-reload
sudo systemctl enable ${moodlight_svc}.service
sudo systemctl restart ${moodlight_svc}.service 

log_success_msg "Testing backlight server: connecting.." 
sleep 2
exec 3<>/dev/tcp/localhost/60485
sleep 1
log_success_msg "Green"
echo "(0, 255, 0)" 1>&3
sleep 2
log_success_msg "Red"
echo "(0, 0, 255)" 1>&3
sleep 2
log_success_msg "Fuchsia"
echo "(255, 0, 255)" 1>&3
sleep 2
log_success_msg "... disconnected"
exec 3<>/dev/null
sleep 1

# Finished 
log_success_msg "Minitower service installation finished successfully" 

# greetings and require rebooting system to take effect.
log_action_msg "Please reboot Raspberry Pi and Have fun!" 
sudo sync

read -p "Do you want to install PyTTY SSH Client? (y/n) : " yesno
if [ "${yesno}" == "y" ] ; then
sudo apt-get install putty -y
fi

read -p "Do you want to reboot now? (type [Yes] to reboot) : " ans
if [ "${ans}" == "Yes" ] ; then
echo "Rebooting..."
sudo reboot
else
echo "Reboot canceled. Please reboot Raspberry Pi later."
fi





