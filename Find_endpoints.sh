#!/bin/bash

# Variables
SUBDOMAINS_FILE='/home/kali/Sushant/subdomains.txt'
LIVE_SUBDOMAINS_FILE="live_subdomains.txt"
ALL_URLS_FILE="all_urls.txt"
COMBINED_URLS_FILE="combined_urls.txt"

# Function to check live subdomains
check_live_subdomains() {
    echo "Checking live subdomains with httprobe..."
    cat $SUBDOMAINS_FILE | httprobe -p http:80 -p https:443 | sort -u | tee $LIVE_SUBDOMAINS_FILE

    echo "Checking live subdomains with httpx..."
    cat $SUBDOMAINS_FILE | httpx -silent -follow-redirects -title -status-code -content-length -extract-regex 'https?://[^\s"]+' -rate-limit 5 -threads 5 -x GET,POST,PUT,DELETE | tee httpx-live-subdomains.txt
}

# Function to gather URLs using various tools
gather_urls() {
    echo "Gathering URLs..."
    > $ALL_URLS_FILE

    while read -r domain; do
        echo "Gathering URLs for: $domain"
        domain_urls_file="${domain}_urls.txt"
        > $domain_urls_file

        # gau
        echo "Using gau..."
        gau --threads 5 $domain | grep -vE '\.(jpg|jpeg|gif|css|tif|tiff|png|ttf|woff|woff2|ico|pdf|svg)$' | tee -a $domain_urls_file

        # hakrawler
        echo "Using hakrawler..."
        echo $domain | hakrawler -depth 3 -insecure -urls -linkfinder | grep $domain | tee -a $domain_urls_file

        # waybackurls
        echo "Using waybackurls..."
        echo $domain | waybackurls | tee -a $domain_urls_file

        # gospider
        echo "Using gospider..."
        gospider -s https://$domain -c 5 --other-source --include-subs -d 3 -t 5 | grep $domain | tee -a $domain_urls_file

        # katana
        echo "Using katana..."
        katana -u $domain -d 3 -aff -kf all -jc | tee -a $domain_urls_file

        # github-endpoints
        echo "Using github-endpoints..."
        github-endpoints -d $domain -t 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 -e -q | tee -a $domain_urls_file

        # xnLinkFinder
        echo "Using xnLinkFinder..."
        xnLinkFinder -i $domain -o $domain_xnlinkfinder_output.txt -d 3 | grep -oE 'https?://[^ ]+' $domain_xnlinkfinder_output.txt | tee -a $domain_urls_file

        # feroxbuster
        echo "Using feroxbuster..."
        feroxbuster -u $domain -t 5 --rate-limit 5 -k -d 3 | grep $domain | tee -a $domain_urls_file

        cat $domain_urls_file >> $ALL_URLS_FILE
    done < $LIVE_SUBDOMAINS_FILE
}

# Function to combine and deduplicate URLs
combine_and_deduplicate_urls() {
    echo "Combining and deduplicating URLs..."
    sort -u $ALL_URLS_FILE | tee $COMBINED_URLS_FILE
}

# Main execution
check_live_subdomains
gather_urls
combine_and_deduplicate_urls

echo "Final URLs have been saved to: $COMBINED_URLS_FILE"
