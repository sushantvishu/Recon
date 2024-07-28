#!/bin/bash

# Check if a subdomains file path is provided
if [ -z "$1" ]; then
    echo "Usage: $0 /home/kali/Sushant/live_subdomains.txt"
    exit 1
fi

# Define the path to the list of subdomains and the directory to save results
SUBDOMAINS_FILE="$1"
OUTPUT_DIR="/home/kali/Sushant/"
COMBINED_URLS_FILE="combined_urls.txt"

# GitHub token for github-endpoints
GITHUB_TOKEN="YOUR GIT TOKEN"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Initialize the combined URLs file
> "$COMBINED_URLS_FILE"

# Process each subdomain
while IFS= read -r subdomain; do
    # Strip http:// or https:// from subdomain
    domain=$(echo "$subdomain" | sed -e 's#http://##' -e 's#https://##')

    # Define the output file for the current domain
    domain_urls_file="$OUTPUT_DIR/${domain}_urls.txt"

    # Initialize the output file
    > "$domain_urls_file"

    # Run various tools and save output to the domain-specific file

    # gau
    echo "Using gau for $domain..."
    gau --threads 5 "$domain" | grep -vE '\.(jpg|jpeg|gif|css|tif|tiff|png|ttf|woff|woff2|ico|pdf|svg)$' | tee -a "$domain_urls_file"

    # hakrawler
    echo "Using hakrawler for $domain..."
    echo "$domain" | hakrawler -d 3 -insecure -u | grep "$domain" | tee -a "$domain_urls_file"

    # waybackurls
    echo "Using waybackurls for $domain..."
    echo "$domain" | waybackurls | tee -a "$domain_urls_file"

    # gospider
    echo "Using gospider for $domain..."
    gospider -s "https://$domain" -c 5 --other-source --include-subs -d 3 -t 5 | grep "$domain" | tee -a "$domain_urls_file"

    # katana
    echo "Using katana for $domain..."
    katana -u "$domain" -d 3 -aff -kf all -jc | tee -a "$domain_urls_file"

    # github-endpoints
    echo "Using github-endpoints for $domain..."
    github-endpoints -d "$domain" -t "$GITHUB_TOKEN" -e -q | tee -a "$domain_urls_file"

    # xnLinkFinder
    echo "Using xnLinkFinder for $domain..."
    xnLinkFinder -i "$domain" -sf "$domain" -o "$domain_urls_file" -d 3

    # feroxbuster
    echo "Using feroxbuster for $domain..."
    feroxbuster -u "$domain" -t 5 --rate-limit 5 -k -d 3 | grep "$domain" | tee -a "$domain_urls_file"

done < "$SUBDOMAINS_FILE"

# Combine all individual domain URLs into one file
echo "Combining all URLs into $COMBINED_URLS_FILE..."
cat "$OUTPUT_DIR"/*_urls.txt | sort -u > "$COMBINED_URLS_FILE"

echo "Script completed. Combined URLs saved in $COMBINED_URLS_FILE."
