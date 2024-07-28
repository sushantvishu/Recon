#!/bin/bash

# Variables
SUBDOMAINS_FILE='/home/kali/Sushant/subdomains.txt'
LIVE_SUBDOMAINS_FILE="live_subdomains.txt"

# Function to check live subdomains
check_live_subdomains() {
    echo "Checking live subdomains with httprobe..."
    cat $SUBDOMAINS_FILE | httprobe -p http:80 -p https:443 | sort -u | tee $LIVE_SUBDOMAINS_FILE

    echo "Checking live subdomains with httpx..."
    cat $SUBDOMAINS_FILE | httpx -silent -follow-redirects -title -status-code -content-length -extract-regex 'https?://[^\s"]+' -rate-limit 5 -threads 5 -x GET,POST,PUT,DELETE | tee -a $LIVE_SUBDOMAINS_FILE
}

# Main execution
check_live_subdomains

echo "Live subdomains have been saved to: $LIVE_SUBDOMAINS_FILE"
