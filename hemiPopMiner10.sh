#!/bin/bash


MAIN_FILE_URL="https://raw.githubusercontent.com/arun993/hemi-miner/master/heminetwork_v0.4.3_linux_amd64.tar.gz"
RPC_URL="wss://testnet.rpc.hemi.network/v1/ws/public"
FEE=60


PINK='\033[1;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'


create_wallet() {
    local wallet_dir="$HOME/$1"
    mkdir -p "$wallet_dir" && cd "$wallet_dir" || return 1

    
    if ! wget "$MAIN_FILE_URL"; then
        printf "${PINK}Error: Unable to download main file for wallet in $wallet_dir${RESET}\n" >&2
        return 1
    fi

   
    if ! tar xvf "$(basename "$MAIN_FILE_URL")"; then
        printf "${PINK}Error: Unable to extract files in $wallet_dir${RESET}\n" >&2
        return 1
    fi

    
    cd heminetwork_v0.4.3_linux_amd64 || return 1

    
    printf "${PINK}Choose an option:\n1) Proceed with new wallet\n2) Import your old wallet${RESET}\n"
    read -r -p "Enter your choice (1 or 2): " choice

    local private_key
    if [[ "$choice" == "1" ]]; then
        
        local new_wallet
        if ! new_wallet=$(./keygen -secp256k1 -json -net="testnet"); then
            printf "${PINK}Error: Failed to generate new wallet${RESET}\n" >&2
            return 1
        fi
        local address_file="$wallet_dir/popm-address.json"
        printf "%s\n" "$new_wallet" > "$address_file"
        
        
        private_key=$(printf "%s" "$new_wallet" | grep -oP '"private_key":\s*"\K[^"]+')

        
        printf "${YELLOW}%s${RESET}\n" "$new_wallet"
        printf "${PINK}Save these keys and press y/Y to proceed${RESET}\n"
        read -r -p "" confirmation
        if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
            return 1
        fi
        printf "${PINK}Send faucet to pubkey_hash address and press y/Y to proceed${RESET}\n"
        read -r -p "" confirmation
        if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
            return 1
        fi

    elif [[ "$choice" == "2" ]]; then
        
        printf "${PINK}Enter your private key: ${RESET}"
        read -r -p "" private_key
    else
        printf "${PINK}Invalid choice, exiting${RESET}\n" >&2
        return 1
    fi

    
    if [[ -n "$private_key" ]]; then
        export POPM_BTC_PRIVKEY="$private_key"
    else
        printf "${PINK}Error: No private key available${RESET}\n" >&2
        return 1
    fi

    
    export POPM_STATIC_FEE=$FEE
    export POPM_BFG_URL=$RPC_URL

    
    ./popmd > "$wallet_dir/miner.log" 2>&1 &
    printf "${PINK}Mining started in wallet %s...${RESET}\n" "$wallet_dir"
}


main() {
    for i in {1..10}; do
        local wallet_dir="hemi$i"
        create_wallet "$wallet_dir"
        
        
        sleep 5
    done

    
    printf "${PINK}Mining successfully started in all 10 wallets${RESET}\n"
    printf "${YELLOW}Code and Script Created by: https://x.com/Arun__993${RESET}\n"
    printf "${YELLOW}Special Thanks to: https://x.com/ZunXBT${RESET}\n"
}


main
