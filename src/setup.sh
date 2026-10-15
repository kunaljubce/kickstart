#!bin/sh

while getopts "r:" opt; do
    case "$opt" in
        r) resolution=$2
    esac
done

# Check for available package upgrades and upgrade the required packages, if needed 
checking_available_updates=`sudo apt update`
echo ${checking_available_updates} | grep "up to date"
if [ $? -eq 0 ]
then
    echo "Nothing to update, proceeding to next steps!"
else
    echo "Updating required packages..."
    sudo apt -y upgrade
fi

# Install `tree` and `curl` packages
echo "Installing tree and curl packages..."
sudo apt install tree curl

# echo $resolution
# #xrandr --output Virtual1 --size 1920x1080
# display_name=`xrandr | grep "connected primary" | cut -d' ' -f1`
# echo "${display_name}"