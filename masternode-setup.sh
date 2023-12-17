#!/bin/bash

collaterl_address="unknown"
domain_name="unknown"
current_ip="uknown"
ifps_id="unknow"
tx_id="unknown"
tx_index="unknown"

bls_secret="unknown"
bls_public_key="unknown"

owner_key_addr="unknow"
voting_key_addr="unknow"
payout_address="unknow"
fee_source_address="unknow"
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
    dig +short myip.opendns.com @resolver1.opendns.com
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
    sudo apt update > /dev/null
    sudo apt upgrade -y > /dev/null
    sudo apt install -y python virtualenv git unzip pv golang-go > /dev/null
    echo "--------------------------------------------------------"
    echo "Completed updating system and installing necessary packages"
    echo "--------------------------------------------------------"
    echo ""

}
############################

############################
# Function to check available memory
check_memory() {
    total_memory=$(free -m | awk '/^Mem:/{print $2}')
    
    if [ "$total_memory" -ge 1900 ]; then
	echo "--------------------------------------------------------"
        echo "Memory check passed: At least 2GB of RAM available."
	echo "--------------------------------------------------------"
    	echo ""
    else
	echo "----------------------------------------------------------------------"
        echo "Memory check failed: Less than 2GB of RAM available. Will not continue"
	echo "----------------------------------------------------------------------"
    	echo ""
        exit 1
    fi
}

############################

############################
next_steps() {

   echo ""
   echo "------------------------------------------------------------------------------"
   echo "Step 1: Please open the debug console how the Historia Core Desktop Wallet."
   echo "        You can do this by clicking Tools > Debug console to open the console."
   echo "------------------------------------------------------------------------------"
   echo ""
}
############################


############################
get_collateral_address() {
   	echo ""
   	echo "------------------------------------------------------------------------------"
   	echo "Step 2: Once in the debug console type in 'getnewaddress'.This will be your"
	echo "collateral address. Copy from the debug console and paste the collateral address"
        echo "below:"
        read -p "Collaterl Address: " collateral_address
	echo "------------------------------------------------------------------------------"
        echo ""
	echo "------------------------------------------------------------------------------"
	echo "You entered the following Collateral Address: $collateral_address"
	echo "------------------------------------------------------------------------------"
	echo ""
}
############################


############################
send_collateral_address() {
    while true; do
        echo ""
        echo "---------------------------------------------------------------------------------"
        echo "Step 3: Send EXACTLY 5000 HTA to your collateral address in your Historia Desktop"
	echo "wallet. You can do this by using the copying and pasting the following  command "
	echo "in the Debug Console:"
        echo ""
	echo "sendtoaddress $collateral_address 5000"
        echo
	echo "------------------------------------------------------------------------------"
        echo ""

        # Prompt for confirmation
        read -p "After you have done that type yes to continue: " confirmation
        if [ "$confirmation" == "yes" ]; then
            break
	else
	    exit
        fi
    done
}
############################


install_historia() {

        echo ""
        echo ""
        echo ""
        echo "---------------------------------------------------------------------------------"
        echo ""
	echo "Step 4: Next we will install Historia on this host (VPS)"
	sleep 15
	echo ""
	echo "------------------------------------------------------------------------------"
        echo ""

echo "--------------------------------------------------------"
echo " Installing Historia"
echo "--------------------------------------------------------"
echo ""
cd /tmp
wget https://github.com/HistoriaOffical/historia/releases/download/0.17.0.4/historiacore-0.17.0.4-x86_64-linux-gnu.tar.gz
mkdir ~/.historiacore
tar xfvz historiacore-0.17.0.4-x86_64-linux-gnu.tar.gz
cp historiacore-0.17.0/bin/historiad ~/.historiacore/
cp historiacore-0.17.0/bin/historia-cli ~/.historiacore/
chmod 777 ~/.historiacore/historia*
rm historiacore-0.17.0.4-x86_64-linux-gnu.tar.gz
rm -r historiacore-0.17.0/

rpcuser=$(uuidgen)
rpcpassword=$(uuidgen)
public_ip=$(curl -s https://api64.ipify.org)

config_content="
#----
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
#----
listen=1
server=1
daemon=1
#----
#masternode=1
#masternodeblsprivkey=
#masternodecollateral=5000
externalip=$public_ip:10101

addnode=202.182.119.4:10101
addnode=149.28.22.65:10101
addnode=149.28.247.81:10101
addnode=45.32.194.49:10101
addnode=45.76.236.45:10101
addnode=209.250.233.69:10101
addnode=104.156.233.45:10101
#----
"

# Echo the configuration to historia.conf
echo "$config_content" > ~/.historiacore/historia.conf

echo "Configuration has been written to ~/.historiacore/historia.conf."


# Start the historia daemon
~/.historiacore/historiad

# Pause for 10 seconds with a status message
echo "Starting historia daemon. Please wait..."
sleep 10


cd ~/.historiacore
git clone https://github.com/HistoriaOffical/sentinel.git
cd sentinel
virtualenv venv
venv/bin/pip install -r requirements.txt
venv/bin/python bin/sentinel.py

(crontab -l ; echo "* * * * * cd ~/.historiacore/sentinel && ./venv/bin/python bin/sentinel.py 2>&1 >> sentinel-cron.log") | crontab -
(crontab -l ; echo "* * * * * pidof historiad || ~/.historiacore/historiad") | crontab -

echo ""
echo "--------------------------------------------------------"
echo " Historia is now installed and running."
echo "--------------------------------------------------------"
echo ""
}

############################


############################
install_ipfs() {

        echo ""
        echo ""
        echo ""
        echo "---------------------------------------------------------------------------------"
        echo ""
        echo "Step 4: Next we will install IPFS on this host (VPS)"
        # Prompt for confirmation
        read -p "Type yes to continue: " confirmation
        if [ "$confirmation" == "yes" ]; then
            break
        fi
        echo ""
        echo "------------------------------------------------------------------------------"
        echo ""


echo ""
echo "------------------------------------------------------------------------------"
echo " Installing IPFS"
echo "------------------------------------------------------------------------------"
echo ""
wget https://dist.ipfs.io/go-ipfs/v0.4.23/go-ipfs_v0.4.23_linux-amd64.tar.gz
tar xvfz go-ipfs_v0.4.23_linux-amd64.tar.gz
sudo mv go-ipfs/ipfs /usr/local/bin/ipfs
rm -rf go-ipfs/

ipfs init -p server

ipfs bootstrap add /ip4/202.182.119.4/tcp/4001/ipfs/QmVjkn7yEqb3LTLCpnndHgzczPAPAxxpJ25mNwuuaBtFJD
ipfs bootstrap add /ip4/149.28.22.65/tcp/4001/ipfs/QmZkRv4qfXvtHot37STR8rJxKg5cDKFnkF5EMh2oP6iBVU
ipfs bootstrap add /ip4/149.28.247.81/tcp/4001/ipfs/QmcvrQ8LpuMqtjktwXRb7Mm6JMCqVdGz6K7VyQynvWRopH
ipfs bootstrap add /ip4/45.32.194.49/tcp/4001/ipfs/QmZXbb5gRMrpBVe79d8hxPjMFJYDDo9kxFZvdb7b2UYamj
ipfs bootstrap add /ip4/45.76.236.45/tcp/4001/ipfs/QmeW8VxxZjhZnjvZmyBqk7TkRxrRgm6aJ1r7JQ51ownAwy
ipfs bootstrap add /ip4/209.250.233.69/tcp/4001/ipfs/Qma946d7VCm8v2ny5S2wE7sMFKg9ZqBXkkZbZVVxjJViyu

ipfs config --json Datastore.StorageMax '"50GB"'
ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Headers '["X-Requested-With", "Access-Control-Expose-Headers", "Range", "Authorization"]'
ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Methods '["POST", "GET"]'
ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
ipfs config --json Gateway.HTTPHeaders.Access-Control-Expose-Headers '["Location", "Ipfs-Hash"]'
ipfs config --json Gateway.HTTPHeaders.X-Special-Header '["Access-Control-Expose-Headers: Ipfs-Hash"]'
ipfs config --json Gateway.NoFetch 'false'
ipfs config --json Swarm.ConnMgr.HighWater '500'
ipfs config --json Swarm.ConnMgr.LowWater '200'


# Create and enable the ipfs service
cat <<EOL | sudo tee /etc/systemd/system/ipfs.service > /dev/null
[Unit]
Description=ipfs.service
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
StartLimitInterval=0
User=$(whoami)
ExecStart=/usr/local/bin/ipfs daemon

[Install]
WantedBy=multi-user.target
EOL


sudo systemctl daemon-reload
sudo systemctl enable ipfs.service
sudo systemctl start ipfs.service

echo "ipfs service has been created and started."
sleep 10


ipfs_id=$(ipfs id | grep -o '"ID": *"[^"]*"' | awk -F'"' '{print $4}')



echo "IPFS ID: $ipfs_id"

ipfs_swarm_peers=$(ipfs swarm peers)

if [ -n "$ipfs_swarm_peers" ]; then
    echo "IPFS is connected to the swarm."
else
    echo "IPFS is not connected to the swarm. Please check your IPFS configuration."
    exit 1
fi

echo ""
echo "------------------------------------------------------------------------------"
}
############################


############################
install_nginx() {

	echo ""
	echo "--------------------------------------------------------------------------------------"
	echo " Installing NGINX"
	echo "--------------------------------------------------------------------------------------"


        echo ""
        echo "Step 5: Next we will install Nginx with SSL and connect it to IPFS on this host (VPS)"
        echo "We will use this domain name:" $domain_name
        echo ""
        # Prompt for confirmation
        read -p "Type yes to continue: " confirmation
        if [ "$confirmation" == "yes" ]; then
            return
        fi
        echo ""
        echo "--------------------------------------------------------------------------------------"
        echo ""



sudo apt install -y nginx

sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo systemctl stop nginx
#$nginx_config="/etc/nginx/sites-available/default"
sudo sed -i "s/server_name _;/server_name $domain_name;/" /etc/nginx/sites-available/default
sudo sed -i '/location \/ {/,/}/d' /etc/nginx/sites-available/default
sudo sed -i "/server_name $domain_name;/a \ \n# BEGIN IPFS SETTINGS\nlocation / {\n    proxy_pass http:\/\/127.0.0.1:8080;\n    proxy_set_header Host \$host;\n    proxy_cache_bypass \$http_upgrade;\n    proxy_set_header X-Forwarded-For \$remote_addr;\n    allow all;\n}\n# END IPFS SETTINGS" /etc/nginx/sites-available/default

sudo certbot --nginx -d "$domain_name"


# Check if Certbot succeeded
if [ $? -eq 0 ]; then
    echo "Certbot successfully obtained the certificate for $domain_name."
echo "1. ownerKeyAddr: $owner_key_addr"
echo "2. votingKeyAddr: $voting_key_addr"
echo "3. payoutAddress: $payout_address"
echo "4. feeSourceAddress: $fee_source_address"
    # Reload Nginx to apply the changes
    sudo systemctl start nginx

    echo "Nginx configuration has been updated with IPFS settings."
else
    echo "Certbot encountered an issue. Please check the Certbot logs for details."
fi


    curl_result=$(curl -s -o /dev/null -w "%{http_code}" "https://$domain_name/ipfs/QmS4ustL54uo8FzR9455qaxZwuMiUhyvMcX9Ba8nUH4uVv/readme")

    if [ "$curl_result" -eq 200 ]; then
        echo "Everything is running correctly. The URL https://$domain_name/ipfs/QmS4ustL54uo8FzR9455qaxZwuMiUhyvMcX9Ba8nUH4uVv/readme is accessible."
    else
        echo "There was an issue. The URL https://$domain_name/ipfs/QmS4ustL54uo8FzR9455qaxZwuMiUhyvMcX9Ba8nUH4uVv/readme is not accessible. Please check your setup."
    fi

}
############################


############################
check_sync_status() {
    sync_status=$(~/.historiacore/historia-cli mnsync status)

    while [[ ! $sync_status == *"MASTERNODE_SYNC_FINISHED"* ]]; do
	echo "Historia blockchain wallet is not fully synced. Waiting for sync..."
    	echo "Block Count: $(~/.historiacore/historia-cli getblockcount)"
    	sleep 30  # Adjust the sleep duration as needed
    done
}

############################



############################
get_user_input() {


        echo ""
        echo "----------------------------------------------------------------------------------------"
        echo " Generating Masternode Register Commands"


        echo ""
        echo "Step 6: Next we will generate the commands to register your masternode"
        echo "All commands should be run in the Historia Core Desktop Wallet -> Tools -> Debug Console"
        echo ""
        # Prompt for confirmation
        read -p "Type yes to continue: " confirmation
        if [ "$confirmation" == "yes" ]; then
            break
        fi
        echo ""
        echo "-----------------------------------------------------------------------------------------"
        echo ""
	echo "In the Debug Console run: masternode outputs";
	read -p "Enter the TX ID of masternode outputs (Example: 8b01c7ed45f3afaef2abb2616bac8eb732bd83b3d20fa1c5ff5e5b6ca150eb53 ): " tx_id
	read -p "Enter the TX Index of masternode outputs (Example: 1) " tx_index
        echo ""
        echo "-----------------------------------------------------------------------------------------"
        echo ""
	echo "In the Debug Console run: bls generate";
	read -p "Enter your BLS Secret Key: " bls_secret
	read -p "Enter your BLS Public Key: " bls_public_key
        echo ""
        echo "-----------------------------------------------------------------------------------------"
        echo ""
	echo "Generate Owner Key Address, in the Debug Console run: getnewaddress";
	read -p "Enter your ownerKeyAddr: " owner_key_addr
        echo ""
        echo "-----------------------------------------------------------------------------------------"
        echo ""
	echo "Generate Voting Key Address, in the Debug Console run: getnewaddress";
	read -p "Enter your votingKeyAddr: " voting_key_addr
        echo ""
        echo "-----------------------------------------------------------------------------------------"
        echo ""
	echo "Generate Payout Key Address, in the Debug Console run: getnewaddress";
	read -p "Enter your payoutAddress: " payout_address
        echo ""
        echo "-----------------------------------------------------------------------------------------"
        echo ""
	echo "Generate Fee Source Key Address, in the Debug Console run: getnewaddress";
	read -p "Enter your feeSourceAddress: " fee_source_address
        echo ""
        echo "-----------------------------------------------------------------------------------------"
        echo ""


        echo ""
        echo "-----------------------------------------------------------------------------------------"
        echo ""
        echo "Please review the information:"
        echo ""
	echo "Collateral Addresss with 5000 HTA: $collaterl_address"
	echo "Domain Name to Register your Masternode: $domain_name"
	echo "IP Address to Register your Masternode:  $current_ip"
	echo "IPFS Peer ID:  $ifps_id"
	echo "Masternode Outputs TX ID: $tx_id"
	echo "Masternode Outputs TX Index: $tx_index"
	echo "BLS Secret: $bls_secret"
	echo "BLS Public Key: $bls_public_key"

	echo "Owner Key Address: $owner_key_addr"
	echo "Voting Key Address: $voting_key_addr"
	echo "Payout Key Address: $payout_address"
	echo "Fee Source Key Address: $fee_source_address"

        read -p "Type yes to continue: " confirmation
        if [ "$confirmation" == "yes" ]; then
            break
        fi

}
############################


############################
update_historia_conf() {
    local conf_file="$HOME/.historiacore/historia.conf"
    local bls_public_key="your_bls_public_key"  # Replace with the actual BLS public key

    # Check if the configuration file exists
    if [ -f "$conf_file" ]; then
        # Use sed to replace the lines in the configuration file
        sed -i 's/^#masternode=1/masternode=1/' "$conf_file"
        sed -i "s/^#masternodeblsprivkey=/masternodeblsprivkey=$bls_public_key/" "$conf_file"
        sed -i 's/^#masternodecollateral=5000/masternodecollateral=5000/' "$conf_file"

        echo "Configuration file updated successfully."
        # Restart historiad
        $HOME/.historiacore/historia-cli stop
    else
        echo "Error: Configuration file not found."
    fi
}
############################



############################
register_prepare() {

        echo ""
        echo "----------------------------------------------------------------------------------------"
        echo " Generating Masternode Register Commands"
        echo ""
        echo ""
        echo "Step 7: Next we will generate the register prepare command for your masternode"
        echo "All commands should be run in the Historia Core Desktop Wallet -> Tools -> Debug Console"
        echo ""
        # Prompt for confirmation
        read -p "Type yes to continue: " confirmation
        if [ "$confirmation" == "yes" ]; then
	        echo ""

		register_prepare_command="protx register_prepare $tx_id $tx_index $current_ip:10101 $owner_key_addr $bls_public_key $voting_key_addr 0 $payout_address $ifps_id $domain_name $fee_source_address"
		
		
		# Display the generated command
		echo "Generated protx register_prepare command:"
		echo "$register_prepare_command"

		echo ""
		echo "Please copy the above 'protx register_prepare' command and paste it into the Historia Core Debug Console."
		echo "To open the Debug Console, go to Historia Core Desktop Wallet -> Tools -> Debug Console."
		echo "After pasting the command, press Enter to execute it and continue the registration process."
		echo "Make sure you are fully synced with the blockchain before proceeding."
	        echo ""
	        echo ""
        	echo ""
	        echo "Please copy and paste the output from the register prepare command below"
		read -p "Enter the 'tx' value from the output: " tx_value
		read -p "Enter the 'signMessage' value from the output: " sign_message_value
		echo ""
	        echo "----------------------------------------------------------------------------------------"
	        echo ""
        fi


}
############################

############################
sign_prepare() {


	sign_message_command="signmessage $collateral_address \"$sign_message_value\""

	# Display the generated signmessage command
	echo ""
        echo "----------------------------------------------------------------------------------------"
        echo ""
        echo "Step 8: Next we will generate the sign message command for your masternode"
	echo "Generated signmessage command:"
	echo ""
	echo "$sign_message_command"
	echo ""
	echo "Please copy the above 'signmessage' command and paste it into the Historia Core Debug Console."
	echo "To open the Debug Console, go to Historia Core Desktop Wallet -> Tools -> Debug Console."
	echo "After pasting the command, press Enter to sign the ProRegTx transaction."
	echo ""
	read -p "Please copy and paste the output from the 'signmessage' command: " sign_message_output
	echo ""
        echo "----------------------------------------------------------------------------------------"
        echo ""
}
############################


############################
register_submit() {
	register_submit_command="protx register_submit $tx_id \"$sign_message_output\""
	
	echo ""
        echo "----------------------------------------------------------------------------------------"
        echo ""
        echo "Step 9: Next we will generate the register_submit command for your masternode"
        echo ""

	echo "Generated protx register_submit command:"
	echo "$register_submit_command"

	echo ""
	echo "Please copy the above 'register_submit' command and paste it into the Historia Core Debug Console."
	echo "To open the Debug Console, go to Historia Core Desktop Wallet -> Tools -> Debug Console."
	echo "After pasting the command, press Enter to submit the signed message and complete the ProRegTx registration."
	echo ""
	echo "Congratulations! If you've followed everything here, your masternode should appear on the network and enabled on the network in 1 block."
	echo "You can check that your masternode is enabled here: https://historia.network/masternodes"
	echo ""
 	echo "You can also confirm that your IPFS is connecting to the Historia Network Blockchain by going to https://<yourDNSName>/ipfs/Qmd76KSvQn51VpsputPNGgdpAQsd73E5ZRxqjhtBsrGS6b/"
	read -p "Once you see an output like 'aba8c22f8992d78fd4ff0c94cb19a5c30e62e7587ee43d5285296a4e6e5af062', you have completed the masternode process. Press Enter to exit."


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
echo ""
echo "*We are here to support you in our Discord or Telegram, come ask questions if you have them"
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
check_memory
next_steps
get_collateral_address
send_collateral_address
install_historia
install_ipfs
install_nginx
check_sync_status
get_user_input
update_historia_conf
register_prepare
sign_prepare
register_submit
