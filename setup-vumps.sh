#!/bin/bash

# Change default delimiter
OIFS=$IFS
IFS=":"

ome=""
thrlb=""
pi_merc=""

# Find devices and check not on same port
# Look in kernel logs for company names
# Read all lines from kernel logs,pull ttyUSB line, save port

# Search for Omega pressure sensor
ome=$(dmesg | grep Omega)
read -a ome <<< "$ome"
ome=$(dmesg | grep "${ome[0]}" | grep ttyUSB | tr ' ' '\n' | tail -1)
if [ -z "$ome" ]; then
	echo "Omega pressure sensor not found"
else
	echo "Omega pressure sensor on $ome"
fi

# Search for Thorlabs servo cube
thrlb=$(dmesg | grep Thorlabs)
read -a thrlb <<< "$thrlb"
thrlb=$(dmesg | grep "${thrlb[0]}" | grep ttyUSB | tr ' ' '\n' | tail -1)
if [ -z "$thrlb" ]; then
	echo "Thorlabs servo cube not found"
elif [ "$ome" = "$thrlb" ]; then
	echo "Thorlabs servo cube cannot be on $ome, another device occupies it"
else
	echo "Thorlabs servo cube on $thrlb"
fi

# Search for PI C-863
pi_merc=$(dmesg | grep 'PI C-863')
read -a pi_merc <<< "$pi_merc"
pi_merc=$(dmesg | grep "${pi_merc[0]}" | grep ttyUSB | tr ' ' '\n' | tail -1)
if [ -z "$pi_merc" ]; then
	echo "PI motor box not found"
elif [ "$pi_merc" = "$thrlb" ]; then
	echo "PI motor box cannot be on $thrlb, another device occupies it"
elif [ "$pi_merc" = "$ome" ]; then
	echo "PI motor box cannot be on $ome, another device occupies it"
else
	echo "PI motor box on $pi_merc"
fi

# Search for Agiltron fiber switch
# Switch masks itself as a FTDI chip, search for switch serial number
agiltron=$(dmesg | grep A900YBPX)
read -a agiltron <<< "$agiltron"
agiltron=$(dmesg | grep "${agiltron[0]}" | grep ttyUSB | tr ' ' '\n' | tail -1)
if [ -z "$agiltron" ]; then
        echo "Agiltron fiber switch not found"
elif [ "$agiltron" = "$thrlb" ]; then
        echo "Agiltron fiber switch cannot be on $thrlb, another device occupies it"
elif [ "$agiltron" = "$ome" ]; then
        echo "Agiltron fiber switch cannot be on $ome, another device occupies it"
elif [ "$agiltron" = "$pi_merc" ]; then
        echo "Agiltron fiber switch cannot be on $pi_merc, another device occupies it"
else
        echo "Agiltron fiber switch on $agiltron"
fi
echo " "


# Correct values in config files
# Assign comport name corresponding to config file
# Lookup alias name
# Write to corresponding config file

# Pressure sensor
comport=pressure_port
ali=$(grep $ome comport.aliases | awk -F'=' '{print $2}')
if [ -z "$ali" ]; then
	echo "Pressure sensor not set"
else
	echo "Pressure sensor set to $ali"
fi
sed -i.bak "/$comport/c\\$comport=$ali" ./vumps-enviro/config/ENVIRO.ini

# Fiber switch
comport=comport
ali=$(grep $agiltron comport.aliases | awk -F'=' '{print $2}')
if [ -z "$ali" ]; then
	echo "Fiber switch not set"
else
	echo "Fiber switch set to $ali"
fi
sed -i.bak "/$comport/c\\$comport=$ali" ./vumps-spx/config/LAMP.ini

# Slit mask stage
comport=comport
ali=$(grep $pi_merc comport.aliases | awk -F'=' '{print $2}')
if [ -z "$ali" ]; then
	echo "Slit mask not set"
else
	echo "Slit mask set to $ali"
fi
sed -i.bak "/$comport/c\\$comport=$ali" ./vumps-spx/config/SLIT.ini

# Focus motor
#ali=COM8

# Undo delimiter setting
IFS=$OIFS

#chmod 776 /dev/ttyUSB*
