#!/bin/bash
# 
if 0; then
BASEDIR=$(dirname $0)
PROJECT_PATH=$(cd $BASEDIR; pwd)
cd
. /lib/lsb/init-functions

#sudo rm -r /usr/local/minitower_kit
sudo mkdir /usr/local/minitower_kit || log_warning_msg "Can't make dir /usr/local/backlight_server" 
#sudo cp ${PROJECT_PATH}/sysinfo.py /usr/local/minitower_kit/sysinfo.py 
sudo cp ${PROJECT_PATH}/backlight_server.py /usr/local/minitower_kit/ 2>/dev/null

sudo apt update
sudo apt upgrade -y

# Enable i2c function on raspberry pi.
log_action_msg "Enable i2c on Raspberry Pi "

sudo sed -i '/dtparam=i2c_arm*/d' /boot/config.txt 
sudo sed -i '$a\dtparam=i2c_arm=on' /boot/config.txt 

if [ $? -eq 0 ]; then
   log_action_msg "i2c has been setting up successfully"
fi

sudo usermod -a -G gpio,i2c pi && log_action_msg "grant privilledges to user pi" || log_warning_msg "Grant privilledges failed!" 

cd /usr/local/ 
if [ ! -d luma.examples ]; then
    sudo git clone https://github.com/rm-hull/luma.examples.git || log_warning_msg "Could not download repository from github, please check the internet connection..." 
fi

sudo cp ${PROJECT_PATH}/sysinfo.py /usr/local/luma.examples/examples/ 

cd /usr/local/luma.examples/ && sudo -H pip3 install -e . && log_action_msg "Install dependencies packages successfully..." || log_warning_msg "Cound not access github repository, please check the internet connections!!!" 
sudo python /usr/local/luma.examples/examples/invaders.py &

sudo pip3 install rpi_ws281x adafruit-circuitpython-neopixel
sudo python3 -m pip install --force-reinstall adafruit-blinka
sudo python /usr/local/minitower_kit/backlight_server.py &
fi
sleep 2
exec 3<>/dev/tcp/localhost/60485
echo "(0, 255, 0)" 1>&3
sleep 1
echo "(0, 255, 255)" 1>&3
sleep 1
echo "(255, 0, 255)" 1>&3

# oled screen display service.
oled_svc="minitower_oled"
oled_svc_file="/lib/systemd/system/${oled_svc}.service"
sudo rm -f ${oled_svc_file}

sudo echo "[Unit]" > ${oled_svc_file}
sudo echo "Description=Minitower Service" >> ${oled_svc_file}
sudo echo "DefaultDependencies=no" >> ${oled_svc_file}
sudo echo "StartLimitIntervalSec=60" >> ${oled_svc_file}
sudo echo "StartLimitBurst=5" >> ${oled_svc_file}
sudo echo "[Service]" >> ${oled_svc_file}
sudo echo "RootDirectory=/" >> ${oled_svc_file}
sudo echo "User=root" >> ${oled_svc_file}
sudo echo "Type=forking" >> ${oled_svc_file}
sudo echo "ExecStart=/bin/bash -c '/usr/bin/python3 /usr/local/luma.examples/examples/sysinfo.py &'" >> ${oled_svc_file}
sudo echo "# ExecStart=/bin/bash -c '/usr/bin/python3 /usr/local/luma.examples/examples/clock.py &'" >> ${oled_svc_file}
sudo echo "RemainAfterExit=yes" >> ${oled_svc_file}
sudo echo "Restart=always" >> ${oled_svc_file}
sudo echo "RestartSec=30" >> ${oled_svc_file}
sudo 
sudo echo "[Install]" >> ${oled_svc_file}
sudo echo "WantedBy=multi-user.target" >> ${oled_svc_file}

log_action_msg "Minitower Service configuration finished." 
sudo chown root:root ${oled_svc_file}
sudo chmod 644 ${oled_svc_file}

log_action_msg "Minitower Service Load module." 
systemctl daemon-reload
systemctl enable ${oled_svc}.service
systemctl restart ${oled_svc}.service 

# mood light service.
moodlight_svc="minitower_lighting_server"
moodlight_svc_file="/lib/systemd/system/${moodlight_svc}.service"
sudo rm -f ${moodlight_svc_file}

sudo echo "[Unit]" > ${moodlight_svc_file}
sudo echo "Description=Minitower light server" >> ${moodlight_svc_file}
sudo echo "DefaultDependencies=no" >> ${moodlight_svc_file}
sudo echo "StartLimitIntervalSec=60" >> ${moodlight_svc_file}
sudo echo "StartLimitBurst=5" >> ${moodlight_svc_file}
sudo echo "Requires=${oled_svc}" >> ${moodlight_svc_file}

sudo echo "[Service]" >> ${moodlight_svc_file}
sudo echo "RootDirectory=/ " >> ${moodlight_svc_file}
sudo echo "User=root" >> ${moodlight_svc_file}
sudo echo "Type=simple" >> ${moodlight_svc_file}
sudo echo "ExecStart=/bin/bash -c 'sudo /usr/bin/python3 /usr/local/backlight_server.py &'"
sudo echo "ExecStart=sudo /usr/bin/moodlight &" >> ${moodlight_svc_file}
sudo echo "RemainAfterExit=yes" >> ${moodlight_svc_file}
sudo echo "Restart=always" >> ${moodlight_svc_file}
sudo echo "RestartSec=30" >> ${moodlight_svc_file}
sudo echo "[Install]" >> ${moodlight_svc_file}
sudo echo "WantedBy=multi-user.target" >> ${moodlight_svc_file}

log_action_msg "Minitower moodlight service installation finished." 
sudo chown root:root ${moodlight_svc_file}
sudo chmod 644 ${moodlight_svc_file}

log_action_msg "Minitower moodlight Service Load module." 
sudo systemctl daemon-reload
sudo systemctl enable ${moodlight_svc}.service
sudo systemctl restart ${moodlight_svc}.service




# Finished 
log_success_msg "Minitower service installation finished successfully." 

# greetings and require rebooting system to take effect.
log_action_msg "Please reboot Raspberry Pi and Have fun!" 
sudo sync


