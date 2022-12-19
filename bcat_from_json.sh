#!/usr/bin/env bash

# assembles a bcat file using ${txid}.json and a bsv node

bcat_part_list=$(jq -r .bcat.parts[] <"${1}")
bcat_file_name=$(jq -r .bcat.manifest[5] <"${1}" | xxd -r -p)
json_sha256sum=$(jq -r .bcat.sha256sum <"${1}")
while read -r line; do
        if [[ $(awk '{ print length }'<<<"${line}") != 64 ]]; then
        	echo "bcat part txid not 64 chars!"
                exit 1
        else
	       jq .vout[0].scriptPubKey.asm<<<$(bitcoin-cli getrawtransaction "${line}" 1) | \
	                sed 's/"//g;s/ /\n/g' | sed -n '4p' | xxd -r -p \
	                >> "${bcat_file_name}"

        fi
done <<<"${bcat_part_list}"
ls "${bcat_file_name}"
local_sha256sum=$(sha256sum "${bcat_file_name}" | cut -d ' ' -f 1 )
echo "json  sha256sum: $json_sha256sum"
echo "local sha256sum: $local_sha256sum"
