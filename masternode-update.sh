#!/bin/bash

collateral_address="unknown"
domain_name="unknown"
current_ip="uknown"
ipfs_id="unknown"
tx_id="unknown"
tx_index="unknown"

bls_secret="unknown"
bls_public_key="unknown"

owner_key_addr="unknown"
voting_key_addr="unknown"
payout_address="unknown"
fee_source_address="unknown"
register_prepare_command="unknown"
register_prepare_output="unknown"
sign_message_command="unknown"
sign_message_output="unknown"
tx_value="unknown"
sign_message_value="unknown"
sign_message="unknown"
collateral_address="unknown"

############################
# Function to get the public IP address of the host
get_public_ip() {
    dig +short myip.opendns.com @208.67.222.222
}
############################

############################
# Function to check if the domain points to the current public IP address
check_domain_ip() {
    domain=$1
    current_ip=$(get_public_ip)
    domain_ip=$(dig +short $domain)

    if [ "$current_ip" == "$domain_ip" ]; then
        echo "The domain $domain points to the current public IP address: $current_ip"
        read -p "Are you ready to continue? (yes/no): " continue_response
        if [ "$continue_response" != "yes" ]; then
            echo "Exiting."
            exit 0
        fi
    else
        echo "The domain $domain does not point to the current public IP address."
        return 1
    fi
}
############################


############################
get_ipfs_id() {
    ipfs_id=$(ipfs id -f "<id>")
    echo "$ipfs_id"
}
############################

############################
check_enter_domain_name() {

    echo ""
    echo "--------------------------------------------------------------------------------------------------------------"
    echo ""
while true; do
    read -p "Enter the domain name that you have already registered and created a DNS A record entree to this host/VPS: " domain_name
    echo ""
    # Check if the domain name is provided
    if [ -z "$domain_name" ]; then
        echo "Please provide a domain name:"
    fi

    # Call the function to check the domain against the current public IP
    check_domain_ip "$domain_name" && break
done

    echo "Domain check successful. Continuing with the script..."
    echo "--------------------------------------------------------------------------------------------------------------"
}

############################


############################
install_dependencies() {
    echo ""
    echo "--------------------------------------------------------"
    echo "Updating system and installing necessary packages..."
    echo "--------------------------------------------------------"
    echo ""
    sudo apt update 
    sudo apt upgrade -y 
    sudo apt install -y python virtualenv git unzip pv golang-go 
    sudo ufw disable
    echo "--------------------------------------------------------"
    echo "Completed updating system and installing necessary packages"
    echo "--------------------------------------------------------"
    echo ""

}


install_historia() {

        echo ""
        echo ""
        echo ""
        echo "---------------------------------------------------------------------------------"
        echo ""
	echo "Next we will update Historiacore on this host (VPS)"
	echo ""
	echo "------------------------------------------------------------------------------"
        echo ""

echo "--------------------------------------------------------"
echo " Updating Historia"
echo "--------------------------------------------------------"
echo ""
cd /tmp
wget https://github.com/HistoriaOffical/historia/releases/download/0.17.1.0/historiacore-0.17.1-x86_64-linux-gnu.tar.gz
sleep 2
tar xfvz historiacore-0.17.1-x86_64-linux-gnu.tar.gz
~/.historiacore/historia-cli stop
sleep 15
tar xfvz historiacore-0.17.1-x86_64-linux-gnu.tar.gz
cp /tmp/historiacore-0.17.1/bin/historiad ~/.historiacore/
cp /tmp/historiacore-0.17.1/bin/historia-cli ~/.historiacore/
chmod 777 ~/.historiacore/historia*
rm historiacore-0.17.1-x86_64-linux-gnu.tar.gz
rm -r historiacore-0.17.1/
cd ~/.historiacore/sentinel/
git pull
virtualenv venv
venv/bin/pip install -r requirements.txt
venv/bin/python bin/sentinel.py

config_content="masternodedns=$domain_name"

# Echo the configuration to historia.conf
echo "$config_content" >> ~/.historiacore/historia.conf

echo "Configuration has been written to ~/.historiacore/historia.conf."


# Start the historia daemon
~/.historiacore/historiad

# Pause for 10 seconds with a status message
echo "Starting historia daemon. Please wait..."
sleep 10


echo ""
echo "--------------------------------------------------------"
echo " Historia is now updated and running."
echo " You can check this by running: ~/.historiacore/historia-cli getinfo"
echo "--------------------------------------------------------"
echo ""
}

############################

############################
# Introductory paragraph
echo "--------------------------------------------------------"
echo "Welcome to the Historia Network Masternode Setup Script!"
echo "--------------------------------------------------------"
echo ""
echo "For documentation please see: https://docs.historia.network/en/latest/masternodes/setup-cdmn.html"
echo ""
echo "The following requirements are:"
echo "1. Collateral Requirement: 5000 HTA in Historia Core Desktop Wallet + a little extra for transaction fees"
echo "2. Static public IPv4 address"
echo "3. Open Ports: TCP 10101, TCP 4001, TCP 443, TCP 80"
echo "4. DNS Name ALREADY pointed to this host with the static public IPv4 address"
echo "5. 2GB of memory and at least 30GB hard drive space (50 GB Recommended)"
echo "6. Collateral Address from your Historia Core Desktop Wallet (We will give you instructions if not)"
echo "7. ownerKeyAddr Address from your Historia Core Desktop Wallet (We will give you instructions if not) "
echo "8. votingKeyAddr Address from your Historia Core Desktop Wallet (We will give you instructions if not)"
echo "9. payoutAddress Address from your Historia Core Desktop Wallet (We will give you instructions if not)"
echo "10. feeSourceAddress Address from your Historia Core Desktop Wallet (We will give you instructions if not)"
echo ""
echo "Please have your Historia Core Desktop wallet running and already synced with the blockchain"
echo ""
echo "Notes:"
echo "*This script does not install a firewall, fail2ban, or secure your server in any means,"
echo "as we don't want to lock you out, We suggest you do those things after you setup this masternode*"
echo ""
echo "*You can quit and restart this script at any time, and things *should* workg correctly the second time"
echo "*but you might see some errors.*"

echo "------------------------------------------------------------------------------"
echo ""
echo "NOTICE to PuTTy Users:"
echo "If you are using PuTTy as your SSH client, and you try to copy via Ctrl-C,"
echo "this will kill the script. Do not use Ctrl-C."
echo ""
echo "To properly copy when using PuTTy:"
echo ""
echo "1. Click the left mouse button in the terminal window, and drag to select text."
echo "When you let go of the button, the text is automatically copied to the clipboard."
echo ""
echo "To properly paste when using PuTTy"
echo "1. Pasting is done using the right mouse button. Clicking the right mouse button"
echo "will paste the contents of the clipboard into the terminal"
echo ""
echo "------------------------------------------------------------------------------"

echo ""
echo "*We are here to support you in our Discord or Telegram, come ask questions if you have them."
echo "*Telegram: https://t.me/HistoriaHTA"
echo "*Discord: https://discordapp.com/invite/b3FJPpn"
echo ""

# Ask if the user is ready to continue
read -p "Do you have the requirements and are ready to continue? (yes/no): " ready_response
if [ "$ready_response" != "yes" ]; then
    echo "Exiting."
    exit 0
fi

# Call functions to check memory and disk space
check_enter_domain_name
install_dependencies
install_historia
