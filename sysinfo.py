#!/usr/bin/python3
# -*- coding: utf-8 -*-
# Copyright (c) 2014-2020 Richard Hull and contributors
# See LICENSE.rst for details.
# PYTHON_ARGCOMPLETE_OK


import os
import sys
import time
from pathlib import Path
from datetime import datetime
from demo_opts import get_device
from luma.core.render import canvas
from PIL import ImageFont
import psutil
import subprocess as sp
from gpiozero import CPUTemperature


def bytes2human(n):
    """
    >>> bytes2human(10000)
    '9K'
    >>> bytes2human(100001221)
    '95M'
    """
    symbols = ('K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y')
    prefix = {}
    for i, s in enumerate(symbols):
        prefix[s] = 1 << (i + 1) * 10
    for s in reversed(symbols):
        if n >= prefix[s]:
            value = int(float(n) / prefix[s])
            return '%s%s' % (value, s)
    return "%sB" % n


def cpu_usage():
    # load average
    cpu = CPUTemperature()
    av1, av2, av3 = os.getloadavg()
    return "t=%.0f'С %.0f-%.0f-%.0f" % (cpu.temperature, 10 * av1, 10 * av2, 10 * av3)

def uptime_usage():
    # uptime, Ip
    uptime = str(datetime.now() - datetime.fromtimestamp(psutil.boot_time()))
    return "%s" % uptime.split('.')[0]

def mem_usage():
    ip = sp.getoutput("hostname -I").split(' ')[0]
    return "IP:%s" % ip
        
def disk_usage(dir):
    ram = psutil.virtual_memory()
    rom = psutil.disk_usage(dir)
    return "%s %.0f%% / %s %.0f%%" % (bytes2human(ram.used), ram.percent, bytes2human(rom.used), rom.percent) 

def network(iface):
    stat = psutil.net_io_counters(pernic=True)[iface]
    return "Tx%s / Rx%s" % (bytes2human(stat.bytes_sent), bytes2human(stat.bytes_recv))

def stats(device):
    # use custom font
    font_path = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'
    font2 = ImageFont.truetype(font_path, 11)

    with canvas(device) as draw:
        draw.text((0, 2), cpu_usage(), font=font2, fill="white")
        if device.height >= 32:
            draw.text((0, 2+13), mem_usage(), font=font2, fill="white")

        if device.height >= 64:
            draw.text((0, 2+13+12), disk_usage('/'), font=font2, fill="white")
            try:
                draw.text((0, 2+13+12+12), network('eth0'), font=font2, fill="white")
            except KeyError:
                # no wifi enabled/available
                draw.text((0, 2+13+12+12), "LAN disconnected!", font=font2, fill="white")
            draw.text((0, 2+13+12+12+13), uptime_usage(), font=font2, fill="white")

device = get_device()

while True:
    stats(device)
    time.sleep(5)
