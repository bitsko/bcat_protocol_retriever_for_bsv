#!/usr/bin/env bash

# retrieve bcat files using a bsv node

# create a json file that includes the file information and
# list of txid where the data is stored

bsv_script_asm(){ jq .vout[0].scriptPubKey.asm; }

bsv_raw_tx_hex(){ bitcoin-cli getrawtransaction "${bsv_bcattxhash}" 1; }

bcat_asm_array(){ bsv_script_asm<<<$(bsv_raw_tx_hex); }

bcat_asm_list_(){ bcat_asm_array | sed 's/"//g;s/ /\n/g'; }

bcat_manifest_(){ bcat_asm_list_ | head -n 8; }

bcat_part_list(){ bcat_asm_list_ | sed '1,8d'; }

name_bcat_file(){
        bcat_file_name=$(head -n 7 <<<$(bcat_manifest_) | tail -n 1 | xxd -r -p)

        if [[ "${bcat_file_name}" == ' ' ]]; then
                bcat_file_name="${1}".file
        fi
}

print_manifest(){
        # bcat_Jmanifest
        while read -r line; do
                if [[ "$line" != 20 && "$line" != "" ]] && \
                        [[ "$line" != 00 && -n "$line" ]] && \
                        [[ "$line" != 0 ]]; then
                        xxdline_array+=( "$(xxd -r -p <<<$line)" )
                fi
        done<<<$(bcat_manifest_)

        bcat_line_array=$(printf '%s\n' "${xxdline_array[@]}" \
                | sed '/^[[:space:]]*$/d' | strings -n 4)

        echo "bcat txid: ${bsv_bcattxhash}"
        echo "${bcat_line_array}"

        name_bcat_file
}

add_bcat_part_(){
        bsv_script_asm<<<$(bitcoin-cli getrawtransaction "${line}" 1) | \
                sed 's/"//g;s/ /\n/g' | sed -n '4p' | xxd -r -p \
                >> "${bcat_file_name}"
}

describe_file_(){
        if [[ -f "${bcat_file_name}" ]]; then
                describe_file1=$(file "${bcat_file_name}")
                describe_file2=$(ls -hl "${bcat_file_name}" | awk '{ print $5 }')
                describe_file3=$(ls -l "${bcat_file_name}" | awk '{ print $5 }')
                echo "${describe_file1} ${describe_file2}"
                bcat_sha256sum=$(sha256sum "${bcat_file_name}" | cut -d ' ' -f 1)
        fi
}

bcat_part_loop(){
        while read -r line; do

                echo "bcat part txid: ${line}"

                if [[ $(wc -m <<<"${line}") != 65 ]]; then
                        echo "bcat part txid not 64 chars!"
                        exit 1
                else
                        add_bcat_part_
                fi
        done <<<$(bcat_part_list)

        describe_file_
}

bsv_bcat_json_(){
cat << BSVBCATJSON
{
  "txid": "${tx_hash}",
  "bcat": {
    "manifest": [
      ${tx_List}
    ],
    "text": [
     ${line_array}
    ],
    "parts": [
      ${bcatPts}
    ],
    "info": "${file_info}",
    "size": "${file_size}",
    "sha256sum": "${bcat_sha256sum}"
  }
}
BSVBCATJSON
}

make_bcat_json(){
tx_List=$(bcat_manifest_)
bcatPts=$(bcat_part_list)
file_info="${describe_file1}"
file_size="${describe_file3}"
line_array="${bcat_line_array}"
tx_List=$(sed 's/\(^\|$\)/"/g;s/$/,/g;$s/.$//;s/\n/ /g'<<<"${tx_List}")
bcatPts=$(sed 's/\(^\|$\)/"/g;s/$/,/g;$s/.$//;s/\n/ /g'<<<"${bcatPts}")
line_array=$(sed 's/\(^\|$\)/"/g;s/$/,/g;$s/.$//;s/\n/ /g'<<<"${line_array}")
bsv_bcatjson_d="bsv_bcat_json_d"
if [[ ! -d "${bsv_bcatjson_d}" ]]; then
        mkdir "${bsv_bcatjson_d}"
fi
bsv_bcat_json_ | jq > "${bsv_bcatjson_d}/${tx_hash}.json"
ls "${bsv_bcatjson_d}/${tx_hash}.json"
}

bsv_node_bcat_(){
        if [[ $(wc -m <<<"${bsv_bcattxhash}") != 65 ]]; then
                echo "txid not 64 chars!"
                exit 1
        else
                print_manifest
                bcat_part_loop
                make_bcat_json
        fi
}

bsv_bcattxhash="$1"
tx_hash="${bsv_bcattxhash}"
bsv_node_bcat_
