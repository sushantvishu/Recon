#!/bin/bash

# Ensure input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

input_file=$1

# Create output directories
mkdir -p scans/masscan scans/nmap scans/nikto scans/wapiti

# Clean input file: remove protocols and ensure valid domain names or IP addresses
cleaned_input_file="cleaned_subdomains.txt"

# Extract domain names and remove empty lines
grep -Eo 'http://|https://|[a-zA-Z0-9.-]+' "$input_file" | sed -E 's|https?://||' | awk NF > "$cleaned_input_file"

# Ensure cleaned input file is not empty
if [ ! -s "$cleaned_input_file" ]; then
    echo "Error: Cleaned input file is empty. Ensure that your input file contains valid domain names or IP addresses."
    exit 1
fi

# Function to run masscan with rate limit
run_masscan() {
    echo "Running Masscan to identify open ports..."
    masscan -p1-65535 --rate=5 -iL $cleaned_input_file | tee scans/masscan/masscan_results.txt
}

# Function to run nmap with cautious settings
run_nmap() {
    echo "Running Nmap to identify open ports and services..."
    nmap -p- -sV -A -T3 -iL $cleaned_input_file -v | tee scans/nmap/nmap_results.txt
}

# Function to run nikto with rate control
run_nikto() {
    echo "Running Nikto to identify vulnerabilities in web servers..."
    while IFS= read -r subdomain; do
        echo "Scanning $subdomain with Nikto..."
        nikto -h $subdomain -Tuning 1 -timeout 15 -max-requests 3 | tee scans/nikto/nikto_${subdomain}.txt
        sleep 5 # Adding delay between scans
    done < "$cleaned_input_file"
}

# Function to run wapiti with delay
run_wapiti() {
    echo "Running Wapiti to identify web application vulnerabilities..."
    while IFS= read -r subdomain; do
        echo "Scanning $subdomain with Wapiti..."
        wapiti -u http://$subdomain --delay 2 -o scans/wapiti/wapiti_${subdomain}.html | tee scans/wapiti/wapiti_${subdomain}.txt
        sleep 10 # Adding delay between scans
    done < "$cleaned_input_file"
}

# Run all scans concurrently with limits to avoid WAF blocking
run_masscan &
run_nmap &
wait
run_nikto &
run_wapiti &
wait

echo "Scanning completed for domains listed in $input_file."
