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
    sudo apt update && sudo apt upgrade -y && sudo apt install git wget curl -y 

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

    print_info ".env.ink-sepolia file updated with new L1_RPC_URL and L1_BEACON_URL values."

    # Call the uni_menu function to display the menu
    master
}




snapshot() {
    # Run the setup.sh file and automatically press 'y' for confirmation
    print_info "Running /root/inkon/node/setup.sh and automatically responding with 'y'."
    echo "y" | sudo bash /root/inkon/node/setup.sh
    print_info "setup.sh completed with automatic 'y' confirmation."

    # Call the uni_menu function to display the menu
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
    print-info "3. Snapshot-Setup"
    print_info "4. Exit"
    print_info ""
    print_info "==============================="
    print_info " Created By : CB-Master "
    print_info "==============================="
    print_info ""
    
    read -p "Enter your choice (1 or 3): " user_choice

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
            exit 0  # Exit the script after breaking the loop
            ;;
        *)
            print_error "Invalid choice. Please enter 1 or 3 : "
            ;;
    esac
}

# Call the uni_menu function to display the menu
master_fun
master
