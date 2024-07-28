#!/bin/bash

# Check if the input file exists
if [ ! -f httpx.txt ]; then
    echo "Input file httpx.txt not found!"
    exit 1
fi

# Create or empty the output files
> subdomains.txt
> temp_subdomains.txt

# Function to process domains and output results
process_domain() {
    domain="$1"
    echo "Processing $domain"
    assetfinder --subs-only "$domain" | tr "\r" "\n" | tee -a temp_subdomains.txt
    subfinder -d "$domain" --silent | tr "\r" "\n" | tee -a temp_subdomains.txt
    amass enum --passive -d "$domain" | tr "\r" "\n" | tee -a temp_subdomains.txt
}

export -f process_domain

# Run the function in parallel and display results in real-time
cat httpx.txt | parallel -j 5 --progress process_domain {}

# Deduplicate and save results
sort -u temp_subdomains.txt > subdomains.txt

# Clean up temporary file
rm temp_subdomains.txt

echo "Subdomain enumeration completed. Results saved in subdomains.txt"

# Run httprobe to check which subdomains are live
echo "Probing for live subdomains..."
cat subdomains.txt | httprobe > live_subdomains.txt

echo "Live subdomain probing completed. Results saved in live_subdomains.txt"
