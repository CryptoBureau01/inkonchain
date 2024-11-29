# !/bin/bash

curl -s https://raw.githubusercontent.com/CryptoBureau01/logo/main/logo.sh | bash
sleep 5

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}



#Function to check system type and root privileges
master_fun() {
    echo "Checking system requirements..."

    # Check if the system is Ubuntu
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" != "ubuntu" ]; then
            echo "This script is designed for Ubuntu. Exiting."
            exit 1
        fi
    else
        echo "Cannot detect operating system. Exiting."
        exit 1
    fi

    # Check if the user is root
    if [ "$EUID" -ne 0 ]; then
        echo "You are not running as root. Please enter root password to proceed."
        sudo -k  # Force the user to enter password
        if sudo true; then
            echo "Switched to root user."
        else
            echo "Failed to gain root privileges. Exiting."
            exit 1
        fi
    else
        echo "You are running as root."
    fi

    echo "System check passed. Proceeding to package installation..."
}


# Function to install dependencies
install_dependency() {
    print_info "<=========== Install Dependency ==============>"
    print_info "Updating and upgrading system packages, and installing curl..."
    sudo apt update && sudo apt upgrade -y && sudo apt install git wget jq curl -y 
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

    # Check if Docker is install
    print_info "Installing Docker..."
    # Download and run the custom Docker installation script
     wget https://raw.githubusercontent.com/CryptoBureau01/packages/main/docker.sh && chmod +x docker.sh && ./docker.sh
     # Check for installation errors
     if [ $? -ne 0 ]; then
        print_error "Failed to install Docker. Please check your system for issues."
        exit 1
     fi
     # Remove the docker.sh file after installation
     rm -f docker.sh


    # Docker Composer Setup
    print_info "Installing Docker Compose..."
    # Download and run the custom Docker Compose installation script
    wget https://raw.githubusercontent.com/CryptoBureau01/packages/main/docker-compose.sh && chmod +x docker-compose.sh && ./docker-compose.sh
    # Check for installation errors
    if [ $? -ne 0 ]; then
       print_error "Failed to install Docker Compose. Please check your system for issues."
       exit 1
    fi
    # Remove the docker-compose.sh file after installation
    rm -f docker-compose.sh


    # Check if geth is installed, if not, install it
    if ! command -v geth &> /dev/null
      then
         print_info "Geth is not installed. Installing now..."
    
    # Geth install
    snap install geth
    
    print_info "Geth installation complete."
    else
        print_info "Geth is already installed."
    fi

    # Print Docker and Docker Compose versions to confirm installation
    print_info "Checking Docker version..."
    docker --version

    print_info "Checking Docker Compose version..."
    docker-compose --version

    # Print Geth version
    print_info "Checking Geth version..."
    geth version

    # Call the uni_menu function to display the menu
    master
}

setup() {
    # Step 1: Create /root/inkon folder
    mkdir -p /root/inkon
    print_info "Folder /root/inkon created successfully."

    # Step 2: Clone the Inkonchain repository inside /root/inkon
    cd /root/inkon
    sudo git clone https://github.com/inkonchain/node.git
    print_info "Inkonchain repository cloned successfully."

    # Step 3: Enter into the node folder
    cd node
    print_info "Entered the /root/inkon/node directory."

    # Step 4: Update .env.ink-sepolia file with the required values
    sudo sed -i 's|L1_RPC_URL=.*|L1_RPC_URL="https://ethereum-sepolia-rpc.publicnode.com"|' .env.ink-sepolia
    sudo sed -i 's|L1_BEACON_URL=.*|L1_BEACON_URL="https://ethereum-sepolia-beacon-api.publicnode.com"|' .env.ink-sepolia
    
    # Update port numbers in .env.ink-sepolia file
    sudo sed -i 's|8545|8540|g' .env.ink-sepolia
    sudo sed -i 's|8546|8541|g' .env.ink-sepolia
    sudo sed -i 's|9545|9540|g' .env.ink-sepolia
    sudo sed -i 's|9222|9220|g' .env.ink-sepolia
    print_info ".env.ink-sepolia file updated with new L1_RPC_URL, L1_BEACON_URL, and port numbers."

    # Step 5: Update docker-compose.yml with new port mappings
    sudo sed -i 's|8545:8545|8540:8540|' docker-compose.yml
    sudo sed -i 's|30303:30303|30308:30308|' docker-compose.yml
    sudo sed -i 's|8546:8546|8541:8541|' docker-compose.yml
    sudo sed -i 's|9545:9545|9540:9545|' docker-compose.yml
    sudo sed -i 's|9222:9222|9220:9222|' docker-compose.yml
    print_info "docker-compose.yml updated with new port mappings."

    # Step 6: Allow new ports in UFW and enable UFW
    sudo ufw allow 8540
    sudo ufw allow 8541
    sudo ufw allow 9540
    sudo ufw allow 9220
    sudo ufw allow 9220/udp
    sudo ufw allow 30308
    sudo ufw allow 30308/udp
    
    sudo ufw enable
    print_info "Ports 8540, 8541, 9540, 9220 (TCP and UDP) allowed in UFW and UFW enabled."

    # Call the master function to display the menu
    master
}

snapshot() {
    # Run the setup.sh file and automatically press 'y' for confirmation
    print_info "Running /root/inkon/node/setup.sh and automatically responding with 'y'."
    echo "y" | sudo bash /root/inkon/node/setup.sh
    print_info "setup.sh completed with automatic 'y' confirmation."

    print_info "Now we are preparing snapshot setup. Please wait for 5 seconds..."
    sleep 5  # Wait for 5 seconds

    # Run the setup.sh file and automatically press 'n' for confirmation
    print_info "Running /root/inkon/node/setup.sh and automatically responding with 'n'."
    echo "n" | sudo bash /root/inkon/node/setup.sh
    print_info "setup.sh completed with automatic 'n' confirmation."

    print_info "Now Snapshot completely setup!"

    # Call the master function to display the menu
    master
}

start_node() {
    INKON_DIR="/root/inkon"

    if [ -d "$INKON_DIR" ]; then
        echo "Directory $INKON_DIR exists."
        cd "$INKON_DIR"

        # Pull the latest updates from the repository
        git pull

        # Start the node using Docker Compose
        print_info "Starting the node using Docker Compose..."
        sudo docker-compose up -d

        # Check if the node started successfully
        if [ $? -eq 0 ]; then
            print_info "Node started successfully!"
        else
            print_error "Failed to start the node. Please check the Docker logs."
        fi
    else
        echo "Error: Directory $INKON_DIR does not exist."
        exit 1
    fi

    # Call the master function to display the menu
    master
}

stop_node() {
    INKON_DIR="/root/inkon"

    if [ -d "$INKON_DIR" ]; then
        echo "Directory $INKON_DIR exists."
        cd "$INKON_DIR"

        # Stop the node using Docker Compose
        print_info "Stopping the node using Docker Compose..."
        sudo docker-compose down

        # Check if the node stopped successfully
        if [ $? -eq 0 ]; then
            print_info "Node stopped successfully!"
        else
            print_error "Failed to stop the node. Please check the Docker logs."
        fi
    else
        echo "Error: Directory $INKON_DIR does not exist."
        exit 1
    fi

    # Call the master function to display the menu
    master
}

sync_status() {
    # Check the sync status of the Optimism node
    print_info "Checking the sync status of the Optimism node..."

    # Execute the curl command and get the output
    sync_output=$(curl -s -X POST -H "Content-Type: application/json" --data \
        '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' \
        http://localhost:9548 | jq -r '.result.syncing')

    # Display the sync status
    if [ "$sync_output" == "true" ]; then
        print_info "The node is currently syncing."
    elif [ "$sync_output" == "false" ]; then
        print_info "The node is fully synced."
    else
        print_info "Unable to determine the sync status. Response: $sync_output"
    fi

    # Call the master function to display the menu
    master
}


check_block() {
    # Check the current block number of the Ethereum node
    print_info "Checking the current block number of the Ethereum node..."

    # Execute the curl command to get the block number
    block_number=$(curl -s http://localhost:8540 -X POST \
        -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params": [],"id":1}' | \
        jq -r .result | sed 's/^0x//' | awk '{printf "%d\n", "0x" $0}')

    # Display the block number
    print_info "Current Block Number: $block_number"

    # Call the master function to display the menu
    master
}


check_finalized_block() {
    # Retrieve the local finalized block number
    local_block=$(curl -s -X POST http://localhost:8540 -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["finalized", false],"id":1}' \
        | jq -r .result.number | sed 's/^0x//' | awk '{printf "%d\n", "0x" $0}')

    # Retrieve the remote finalized block number
    remote_block=$(curl -s -X POST https://rpc-gel-sepolia.inkonchain.com/ -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["finalized", false],"id":1}' \
        | jq -r .result.number | sed 's/^0x//' | awk '{printf "%d\n", "0x" $0}')

    # Print both block numbers
    print_info "Local finalized block: $local_block"
    print_info "Remote finalized block: $remote_block"

    # Call the master function to display the menu
    master
}


check_private_key() {
    # Define the path to the private key file
    PRIVATE_KEY_FILE="/root/inkon/node/var/secrets/jwt.txt"
    
    # Check if the file exists
    if [[ -f "$PRIVATE_KEY_FILE" ]]; then
        # Read and display the private key
        PRIVATE_KEY=$(cat "$PRIVATE_KEY_FILE")
        print_info "Private Key: $PRIVATE_KEY"
    else
        print_error "Private key file not found at $PRIVATE_KEY_FILE"
    fi

    # Call the master function to display the menu
    master
}

import_private_key() {
    # Define the path to the private key file
    PRIVATE_KEY_FILE="/root/inkon/node/var/secrets/jwt.txt"
    
    # Check if the private key file already exists and has content
    if [[ -f "$PRIVATE_KEY_FILE" && -s "$PRIVATE_KEY_FILE" ]]; then
        # Display the existing key and prompt the user for confirmation
        echo "A private key already exists in $PRIVATE_KEY_FILE."
        read -p "Do you want to overwrite the existing private key? (y/n): " confirm
        
        if [[ "$confirm" != "y" ]]; then
            print_info "Operation cancelled. Existing private key was not modified."
            return
        fi
        
        # Remove the old private key if the user chose to overwrite
        rm -f "$PRIVATE_KEY_FILE"
        print_info "Old private key deleted."
    fi

    # Prompt the user to enter a new private key with 0x prefix
    read -p "Please enter your new private key (starting with 0x): " USER_PRIVATE_KEY

    # Validate that the private key starts with "0x"
    if [[ "$USER_PRIVATE_KEY" == 0x* ]]; then
        # Save the new private key to the file
        echo "$USER_PRIVATE_KEY" > "$PRIVATE_KEY_FILE"
        print_info "New private key has been successfully saved to $PRIVATE_KEY_FILE"
    else
        print_error "Invalid input: Private key must start with '0x'."
    fi

    # Call the master function to display the menu
    master
}



logs_check() {
    # Check the logs of the Docker container and print the last 100 lines
    print_info "Fetching the last 100 lines of Docker logs..."
    sudo docker compose logs -f | head -n 100

    # Call the master function to display the menu
    master
}





# Function to display menu and prompt user for input
master() {
    print_info "==============================="
    print_info "  InkonChain Node Tool Menu    "
    print_info "==============================="
    print_info ""
    print_info "1. Install-Dependency"
    print_info "2. Inkon-Setup"
    print_info "3. SnapShot-Setup"
    print_info "4. Start-Node"
    print_info "5. Check-Private-Key"
    print_info "6. Import-Private-Key"
    print_info "7. Check-Block"
    print_info "8. Final-Blocks"
    print_info "9. Logs-Checker"
    print_info "10. Stop-Node"
    print_info "11. Exit"
    print_info ""
    print_info "==============================="
    print_info " Created By : CB-Master "
    print_info "==============================="
    print_info ""
    
    read -p "Enter your choice (1 or 10): " user_choice

    case $user_choice in
        1)
            install_dependency
            ;;
        2)
            setup
            ;;
        3) 
            snapshot
            ;;
        4)
            start_node
            ;;
        5)
            check_private_key
            ;;
        6)
            import_private_key
            ;;
        7)
            check_block
            ;;
        8)
            check_finalized_block
            ;;
        9)
            logs_check
            ;;
        10)  
            stop_node
            ;;
        11)
            exit 0  # Exit the script after breaking the loop
            ;;
        *)
            print_error "Invalid choice. Please enter 1 or 10 : "
            ;;
    esac
}

# Call the uni_menu function to display the menu
master_fun
master
