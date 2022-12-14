#!/usr/bin/env bash

# work in progress

# bcat_retriever.sh uses WhatsOnChain.com api and BSV-JS to download files stored on the bsv blockchain

# example usage:
# $ ./bcat_retriever.sh e731ca882656dd61c42d56363eaa63b585f40e1d6f18caeb0c22dec7bf8fc6c3
# spec: https://bcat.bico.media/
# upload files here: https://bico.media/

# example_txid=e731ca882656dd61c42d56363eaa63b585f40e1d6f18caeb0c22dec7bf8fc6c3

tput_coloring(){
	if [[ -z $(command -v tput) ]]; then
		echo "requires tput"
		exit 1
	else
		red=$(tput setaf 1)
		blue=$(tput setaf 4)
		normal=$(tput sgr0)
		green=$(tput setaf 2)
		bright=$(tput bold)
	fi
}

echo_red(){ echo "${red}${1}${normal}"; }

echo_blue(){ echo "${bright}${blue}${1}${normal}"; }

echo_green(){ echo "${bright}${green}${1}${normal}"; }

echo_bright(){ echo "${bright}${1}${normal}"; }

size_checker(){
	if [[ $(wc -m <<<"$tx_hash") == 65 ]]; then
       		echo "${bright}bcat tx:  ${green}$tx_hash${normal}"
	else
       		echo_red "error ; tx_hash not 64 chars"
	        exit 1
		script_exit
	fi
}

deps_checker(){
	if ! [ -x "$(command -v npm)" ]; then
		echo_red "install npm"
		exit 1
	fi
	if [ ! -d node_modules/bsv/ ]; then
		echo_bright "installing BSV js library"
		npm i --prefix "$(pwd)" bsv --save
	fi
	if [ $(npm list bsv | awk NR==2 | tr -dc '0-9' | cut -c 1) -eq "1" ]; then
		echo_red "bsvjs 1x installed, needs bsvjs 2x"
		exit 1
	fi
	if ! [ -x "$(command -v xxd)" ]; then
		echo_red "install xxd"
		exit 1
	fi
	if ! [ -x "$(command -v curl)" ]; then
		echo_red "install curl"
		exit 1
	fi
}

set_asm_txo(){
node << BSVJSFROMHEXTOASM
let bsv = require('bsv')
var script = bsv.Script.fromHex('$get_hex')
console.log(script.toAsmString())
BSVJSFROMHEXTOASM
}

hash2asm_variables(){
	tx_vout=0
	bsv_api='v1'
	bsv_net='main'
	wocurl1="https://api.whatsonchain.com/${bsv_api}/"
	wocurl2="/bsv/${bsv_net}/tx/${tx_hash}/out/${tx_vout}/hex"
	woc_url="${wocurl1}${wocurl2}"
	bcat_address=15DHFxWZJT58f9nhyGnsRBqrgwK4W6h4Up
	bcat_transaction=313544484678575a4a54353866396e6879476e735242717267774b34573668345570
	bcat_tx_part=31436844487a646431483477536a67474d48796e645a6d3671784544476a71704a4c
}

name_bcat_file(){
		bc_Name="$(cut -d ' ' -f 7 <<<"$asm_txo" | xxd -r -p)"
	        if [[ "$bc_Name" == ' ' ]]; then
			bc_Name="$tx_hash".file
		fi
		if [[ -f $bc_Name ]]; then
                	bc_Name="${bc_Name}.dup"
        	fi
}

hash2asm(){
	hash2asm_variables
	if [[ $(wc -m <<<"$tx_hash") == 65 ]]; then
        	get_hex="$(curl -s --location --request GET $woc_url)"
	else
	        echo_red "error; tx_hash not 64 chars"
	        exit 1
		script_exit
	fi
	asm_txo=$(set_asm_txo)
	if [[ -z "$asm_txo" ]]; then
        	echo_red "error; asm returned null"
	        exit 1
		script_exit
	else
		asm_arr="$(sed 's/ /\n/g' <<<"$asm_txo")"
	fi

	if [[ "$(cut -d ' ' -f 3 <<<"$asm_txo")" ==  "$bcat_transaction" ]]; then
        	bcatPts="$(sed '1,8d' <<<"$asm_arr")"
		tx_List=$(head -n 8 <<<"$asm_arr")
		while read -r line; do
			if [[ "$line" != 20 && "$line" != "" ]] && [[ "$line" != 00 && -n "$line" ]]; then
				xxdline_array+=( "$(xxd -r -p <<<$line)" )
			fi
		done<<<"$tx_List"
		line_array=$(printf '%s\n' "${xxdline_array[@]}" | sed '/^[[:space:]]*$/d' | strings -n 4)
		echo_blue "${line_array}"
	        name_bcat_file
		echo_bright "$(wc -l <<<"$bcatPts") bcat parts:"
	elif [[ "$(cut -d ' ' -f 3 <<<"$asm_txo")" ==  "$bcat_tx_part" ]]; then
	        xxd -r -p <<<"$(sed -n '4p' <<<"$asm_arr")" >> "$bc_Name"
	else
	        echo_red "error; not a bcat transaction hash"
		exit 1
		script_exit
	fi
}

concatenate_parts(){
	while read -r line; do
        	tx_hash=$(printf '%s\n' "$line")
	        echo_green "$tx_hash"
	        hash2asm "$tx_hash"
	done<<<"$bcatPts"
}

print_location(){
	if [[ -n "$bc_Name" ]]; then
		file_info=$(file "$bc_Name")
		echo "${bright}${blue}${file_info}${normal}"
		echo_bright "$PWD/\"$bc_Name\""
		file_size=$(ls -al "${bc_Name}" | awk '{ print $5 }')
		file_sha256sum=$(sha256sum "${bc_Name}" | cut -d ' ' -f 1 )
	fi
}

script_exit(){
	unset bsv_net bsv_api tx_vout asm_txo get_hex asm_arr tx_List \
	bcatPts bc_Name tx_hash wocurl1 wocurl2 woc_url deps_checker \
	hash2asm concatenate_parts print_location bcat_transaction \
	bcat_tx_part echo_red echo_blue echo_bright tput_coloring \
	example_txid size_checker xxdline_array bcat_address file_info \
	echo_green script_exit
}

bsv_bcat_json_(){
cat << BSVBCATJSON
{
  "txid": "${tx_hash_}",
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
    "sha256sum": "${file_sha256sum}"
  }
}
BSVBCATJSON
}

sed_make_json_list(){
	sed 's/\(^\|$\)/"/g;s/$/,/g;$s/.$//;s/\n/ /g'
}

make_bcat_json(){
tx_List=$(sed_make_json_list<<<"${tx_List}")
bcatPts=$(sed_make_json_list<<<"${bcatPts}")
line_array=$(sed_make_json_list<<<"${line_array}")
bsv_bcatjson_d="bsv_bcat_json_d"
if [[ ! -d "${bsv_bcatjson_d}" ]]; then
        mkdir "${bsv_bcatjson_d}"
fi

# add duplicates logic here

bsv_bcat_json_ | jq > "${bsv_bcatjson_d}/${tx_hash_}.json"
echo "Json manifest is located at:"
ls "${bsv_bcatjson_d}/${tx_hash_}.json"
}

tput_coloring
if [[ -p "/dev/stdin" ]]; then
      	tx_hash="$(cat)"
else
       	tx_hash="$1"
        if [[ -z "$1" ]]; then
                echo_bright "provide a txid as \$1"
		echo_green "./bcat_retriever.sh $example_txid"
       	        exit 1
		script_exit
        fi
fi
tx_hash_="${tx_hash}"

deps_checker
size_checker
hash2asm
concatenate_parts
print_location
make_bcat_json
script_exit
