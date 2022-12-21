#!/usr/bin/env bash

# retrieve bcat files using a bsv node

# bcat_retriever.sh uses a local bitcoin node by default;
# but if not present, it will use the WhatsOnChain.com api and BSV-JS
# to download files stored on the bsv blockchain

# example usage:
# $ bash bcat_retriever.sh e731ca882656dd61c42d56363eaa63b585f40e1d6f18caeb0c22dec7bf8fc6c3
# spec: https://bcat.bico.media/
# upload files here: https://bico.media/

# example_txid=e731ca882656dd61c42d56363eaa63b585f40e1d6f18caeb0c22dec7bf8fc6c3

# exit script upon error
set -e

potential_index_txid="$1"

# if manual_datasource is set to true; it will use a non-default datasource
# ie; if you have a node and still want to use whatsonchain api
manual_datasource=false

# if save_json_manifest is set to true; it will create
# a json file that includes the bcat file information and
# list of txid where the data is stored
save_json_manifest=false

# if save_raw_transactions is set to true; it will
# download the raw hexadecimal bcat and bcat part
# transactions into the 'rawtx' folder in the data directory
save_raw_transactions=false

# if save_bcat_list is set to true; saves a hexadecimal list in the current directory
# of each bcat protocol argument, as the file <txid>.bcat
save_bcat_list=false

# if verbost_output is set to true, it prints various
# datas to the command line as it grabs the file
verbose_output=true
# download this script from commandline:
# wget -N -q --show-progress https://raw.githubusercontent.com/bitsko/bcat_protocol_retriever_for_bsv/main/bcat_retriever.sh

# grabs the metaid/metafile by metafile/index txid and concatenates the parts into a file

# defaults to using a bitcoin-sv node, if one is not available, uses whatsonchain api

# potential_index_txid="$1"
# 熊3.jpg = da12d7ffb90af9491e3c5015e01e9af4ef46707d95f8d9e44aa5a4de40c67bfa
# Time.mp3 = e07ac192fc091bc63a817bf7aff19695a64ee1ab350ac97c338b6115f69872e3
# test_mp3 = 132ef07894b2bdd12eb96cf29eb62933ba6b14bf3db304560935b12346a84060

verbose_output=false
manual_datasource=false


tput_color(){
	tput_coloring=false
	if [[ $(command -v tput) ]]; then
		tput_coloring=true
		red=$(tput setaf 1)
		blue=$(tput setaf 4)
		normal=$(tput sgr0)
		green=$(tput setaf 2)
		bright=$(tput bold)
	fi

}

echo_red(){
	if [[ $tput_coloring == true ]]; then
		echo "${red}${1}${normal}"
	else
		echo "$1"
	fi
}

echo_blue(){
	if [[ $tput_coloring == true ]]; then
		echo "${bright}${blue}${1}${normal}"
	else
		echo "$1"
	fi
}

echo_green(){
	if [[ $tput_coloring == true ]]; then
		echo "${bright}${green}${1}${normal}"
	else
		echo "$1"
	fi
}

echo_sameline_green(){
	if [[ $tput_coloring == true ]]; then
		echo -e "\e[1A\e[K${bright}${green}${1}${normal}"
	else
		echo -e "\e[1A\e[K$1"
	fi
}

echo_bright(){
	if [[ $tput_coloring == true ]]; then
		echo "${bright}${1}${normal}"
	else
		echo "$1"
	fi
}

echo_n_bright(){
	if [[ $tput_coloring == true ]]; then
		echo -n "${bright}${1}${normal}"
	else
		echo -n "$1"
	fi
}

input_check(){

	if [[ -z $potential_index_txid ]]; then
		echo "give the txid as position parameter 1"
		script_exit
		exit 1
	elif [[ ! $potential_index_txid =~ ^[a-f0-9]{64}$ ]]; then
		echo "is the input string made of hexadecimal?"
		script_exit
		exit 1
	elif [[ $(awk '{ print length }'<<<"$potential_index_txid") == 64 ]]; then
		if [[ $verbose_output == true ]]; then
			if [[ $tput_coloring == true ]]; then
				echo "${bright}bcat tx:  ${green}${potential_index_txid}${normal}"
			else
				echo "bcat tx:	$1"
			fi
		fi
	else
		echo_red "error ; tx_hash not 64 chars"
		echo_red "$potential_index_txid"
		script_exit
		exit 1
	fi
}

set_data_source(){
	test_cli_rawtx(){
		# verifies that the node is up and has the raw tx
		if [[ $(command -v bitcoin-cli) ]]; then
			bitcoin-cli getrawtransaction "$potential_index_txid"
		fi
	}

	test_woc_avail(){
		# expected_response="Whats On Chain"
		curl -s "https://api.whatsonchain.com/v1/bsv/main/woc"
	}

	if [[ $(test_cli_rawtx) ]]; then
		selected_datasource=BITCOIN_NODE
	elif [[ $(test_woc_avail) == "Whats On Chain" ]]; then
		selected_datasource=WHATS_ON_CHAIN
	else
		echo "error: no raw tx from node and no response from woc"
		script_exit
		exit 1
	fi

	if [[ $manual_datasource == true ]]; then
		# override automatic datasource selection
		# options are BITCOIN_NODE (default if you have a node up)
		# and WHATS_ON_CHAIN (default if you do not have a node up)
		# selected_datasource=BITCOIN_NODE
		selected_datasource=WHATS_ON_CHAIN
	fi
	if [[ $selected_datasource == BITCOIN_NODE ]]; then

		get_data(){
			bitcoin-cli getrawtransaction "$1" 1
		}
		get_hex(){
			bitcoin-cli getrawtransaction "$1" 0
		}
	elif [[ $selected_datasource == WHATS_ON_CHAIN ]]; then

		get_data(){
 		       curl -s --location --request GET "https://api.whatsonchain.com/v1/bsv/main/tx/hash/${1}"
		}
		get_hex(){
        		curl -s --location --request GET \
        		"https://api.whatsonchain.com/v1/bsv/main/tx/${1}/hex"
		}
	else
		echo "no datasource available"
		exit 1
	fi

	if [[ $verbose_output == true ]]; then
		echo_blue "Using $selected_datasource to obtain file..."
	fi
}

deps_checker(){
	if ! [[ -x "$(command -v xxd)" ]]; then
		echo_red "install xxd"
		script_exit
		exit 1
	fi
	if ! [[ -x "$(command -v jq)" ]]; then
		echo_red "install jq"
		script_exit
		exit 1
	fi
	if [[ $selected_datasource == WHATS_ON_CHAIN ]]; then
		if ! [[ -x "$(command -v npm)" ]]; then
			echo_red "install npm"
			script_exit
			exit 1
		fi
		if [[ ! -d node_modules/bsv/ ]]; then
			echo_n_bright "installing BSV js library..."
			npm i --prefix "$(pwd)" bsv --save &>/dev/null
			echo -ne "\r"
		fi
		bsvjs_ver=$(npm list bsv | awk NR==2 | tr -dc '0-9' | cut -c 1)
		if [[ $bsvjs_ver -eq "1" ]]; then
			echo_red "bsvjs 1x installed, needs bsvjs 2x"
			script_exit
			exit 1
		fi
		if ! [[ -x "$(command -v curl)" ]]; then
			echo_red "install curl"
			script_exit
			exit 1
		fi

	fi
}

txid_datatype_checker(){
	opreturn_check(){
		current_vout=0
		vout_count=$(jq '.vout | length'<<<"$transaction_json")
		while [[ $current_vout -lt $vout_count ]]; do
			check_opreturn=$(
				jq -r .vout[$current_vout].scriptPubKey.asm \
				<<<"$transaction_json"	| awk '{ print $2 }'
			)
			if [[ $verbose_output == true ]]; then
				echo "check_opreturn $check_opreturn"
			fi
			if [[ $check_opreturn == OP_RETURN ]]; then
				opreturn_vout=$(
					jq -r .vout[$current_vout].scriptPubKey.asm \
					<<<"$transaction_json"
				)
				if [[ $verbose_output == true ]]; then
					echo "opreturn vout: $opreturn_vout"
				fi
			fi
			current_vout=$((current_vout + 1))
		done
	}
	#bsv_downloader_datasource=WHATS_ON_CHAIN
	#verbose_output=false
	#get_data_function
	opreturn_check
	potential_bcat_txid=$(
		awk '{ print $3 }'<<<"$opreturn_vout"  \
		| xxd -r -p \
		| strings
	)

	if [[ $potential_bcat_txid == 15DHFxWZJT58f9nhyGnsRBqrgwK4W6h4Up ]]; then
		datafile_index_type=BCAT_INDEX
		if [[ $verbose_output == true ]]; then
			echo "this is a bcat transaction"
		fi
	fi

	potential_metaid_file=$(
		awk '{ print $6 }'<<<"$opreturn_vout"  \
		|  xxd -r -p \
		| strings
	)

	if [[ $potential_metaid_file == metaid ]]; then
		if [[ $verbose_output == true ]]; then
			echo "this is a metaid transaction"
		fi
		metaid_tx_file_type=$(
			awk '{ print $11 }'<<<"$opreturn_vout"
		)
		if [[ $metaid_tx_file_type == 6d65746166696c652f696e646578 ]]; then
			datafile_index_type=METAFILE_INDEX
			if [[ $verbose_output == true ]]; then
				echo "this is a metfile/index transaction"
			fi
		fi
	fi
}

metafile_retriever_function(){
	
	describe_metafile(){

		metafile_json=$(
			jq -r .vout[1].scriptPubKey.asm<<<"$transaction_json" \
			| tr ' ' '\n' \
			| awk NR==8 \
			| xxd -r -p \
			| jq
		)

		if [[ -z $metafile_json ]]; then
			echo "the txid does not have any data in argument # 8 of the scriptPubKey asm"
			exit 1
		fi

		metafile_name=$(
			jq .name<<<"${metafile_json}" | sed "s/[']//g" | sed 's/["]//g'
		)
	
		if [[ -z $metafile_name ]]; then
			echo "the metafile index is missing the name argument"
			metafile_name="${potential_index_txid}.file"
		fi
	
		metafile_chunkList=$(
			jq -r .chunkList[].txid <<<"${metafile_json}"
		)
	}

	concatenate_metafile_chunks(){

	if [[ -n $metafile_chunkList ]]; then
		echo ""
		chunkpiece=1
		while IFS=' ' read -r line; do

			echo -e "\e[1A\e[Kadding chunkpiece from $metaid_datasource; txid: $chunkpiece, $line"

			get_data $line \
			| jq -r .vout[1].scriptPubKey.asm \
			| tr ' ' '\n' \
			| awk NR==8 \
			| xxd -r -p \
			>> "$metafile_name"

			chunkpiece=$((chunkpiece + 1))

		done<<<"$metafile_chunkList"
	else
		echo "missing chunkList!"
		exit 1
	fi
	}
	
	print_file_information(){
		file "$metafile_name"
	}
	
	_curl_GET(){
	        curl -s --location --request GET "https://api.whatsonchain.com/v1/bsv/main/tx/hash/${1}"
	}
	

	metafile_grabber_main(){
		set_data_source
	        input_check
		describe_metafile
		concatenate_metafile_chunks
		print_file_information
		if [[ $verbose_output == true ]]; then
			declare -f get_data
		fi
		script_exit
	}

	metafile_grabber_main || script_exit
}

bcat_retriever_function(){
	get_bcat_script_asm(){
#		bsv_script_asm=$(
#			get_data "${1}" | jq .vout[0].scriptPubKey.asm
#		)
		bsv_script_asm=$(
			jq .vout[0].scriptPubKey.asm <<<"$transaction_json"
		)
		if [[ $save_raw_transactions == true ]]; then
			if [[ ! -f "$bsv_rawtx_dir/$1.rawtx" ]]; then
				get_hex "$1" \
				> "$bsv_rawtx_dir/$1.rawtx"
				if [[ $verbose_output == true ]]; then
					echo_green "saving $1.rawtx"
					echo
				fi
			fi
		fi
		protocol_check_array+=( $(sed 's/["]//g;/^$/d'<<<$bsv_script_asm) )
	}
	
	bcat_asm_list_(){
		sed 's/"//g;s/ /\n/g'<<<"$bsv_script_asm"
	}
	
	bcat_manifest_(){
		bcat_asm_list_ | head -n 8
	}
	
	bcat_part_list(){
		bcat_asm_list_ | sed '1,8d'
	}
	
	print_manifest(){
	        # bcat_Jmanifest
	        while read -r line; do
	                if [[ "$line" != 20 && "$line" != "" ]] && \
	                        [[ "$line" != 00 && -n "$line" ]] && \
	                        [[ "$line" != 0 ]]; then
	                        xxdline_array+=( "$(xxd -r -p <<<$line)" )
				manifest_array+=( "$line" )
		         fi
	        done<<<$(bcat_manifest_)
	        bcat_line_array=$(printf '%s\n' "${xxdline_array[@]}" \
	                | sed '/^[[:space:]]*$/d' | strings -n 4)
		if [[ $verbose_output == true ]]; then
			echo_blue "${bcat_line_array[@]}"
		fi
	        name_bcat_file
	}
	
	name_bcat_file(){
	        bcat_file_name=$(head -n 7 <<<$(bcat_manifest_) | tail -n 1 | xxd -r -p)
	        if [[ "${bcat_file_name}" == ' ' ]]; then
	                bcat_file_name="${1}".file
	        fi
	        if [[ -f $bcat_file_name ]]; then
	                bcat_file_name="${bcat_file_name}.dup.$EPOCHSECONDS"
	        fi
	}
	
	describe_file_(){
	        if [[ -f "${bcat_file_name}" ]]; then
	                describe_file1=$(file "${bcat_file_name}")
	                describe_file2=$(ls -hl "${bcat_file_name}" | awk '{ print $5 }')
	                describe_file3=$(ls -l "${bcat_file_name}" | awk '{ print $5 }')
			if [[ $verbose_output == true ]]; then
				echo -e "\e[1A\e[K${describe_file1} ${describe_file2}"
				echo
			fi
			echo_sameline_green "$bcat_file_name"
	                bcat_sha256sum=$(sha256sum "${bcat_file_name}" | cut -d ' ' -f 1)
	        fi
	}
	
	bcat_part_loop(){
	        while IFS=' ' read -r line; do
			bcat_parts_array+=( $(sed 's/"//g'<<<"$line") )
	                echo -e "\e[1A\e[Kgrabbing bcat part txid: ${line}"
	                if [[ $(awk '{ print length }'<<<"$line") != 64 ]]; then
	                        echo "bcat part txid not 64 chars!"
				script_exit
	                        exit 1
	                else
				bsv_script_asm=$(
					get_data "${line}" | jq .vout[0].scriptPubKey.asm
					)
				if [[ $save_raw_transactions == true ]]; then
					if [[ ! -f "$bsv_rawtx_dir/$line.rawtx" ]]; then
						get_hex "$line" \
						> "$bsv_rawtx_dir/$line.rawtx"
						if [[ $verbose_output == true ]]; then
							echo_green "saving $line.rawtx"
							echo
						fi
					fi
				fi
				bcat_part_hex=$(awk '{ print $4 }'<<<"$bsv_script_asm")
				printf '%s' "$bcat_part_hex" | xxd -r -p >> "${bcat_file_name}"
	                fi
	        done <<<$(bcat_part_list)
	        describe_file_
	}
	
	bsv_bcat_json_(){
	cat <<- BSVBCATJSON
	{
	  "txid": "${json_txid}",
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
	
	sed_function(){
		sed 's/\(^\|$\)/"/g;s/$/,/g;$s/.$//;s/\n/ /g'<<<"$1"
	}
	
	make_bcat_json(){
		json_txid="$1"
		tx_List="$(printf '%s\n' ${manifest_array[@]})"
		bcatPts=$(printf '%s\n' "${bcat_parts_array[@]}")
		file_info="${describe_file1}"
		file_size="${describe_file3}"
		line_array="${bcat_line_array}"
		tx_List=$(sed_function "${tx_List}")
		bcatPts=$(sed_function "${bcatPts}")
		line_array=$(sed_function "${line_array}")
	
		json_filename="${bsv_bcatjson_d}/${1}.json"
		if [[ -f $json_filename ]]; then
			json_filename="${json_filename}.dup.$EPOCHSECONDS"
		fi
	
		# validates jq is parseable as it creates the json file
		bsv_bcat_json_ | jq > "${json_filename}"
	
		# if jq is not parsing correctly, do not require it
		#bsv_bcat_json_  > "${json_filename}"
	
		if [[ $verbose_output == true ]]; then
			echo_bright "Json manifest is located at:"
			echo_blue "$(ls ${json_filename})"
			jq < "${json_filename}"
		fi
	}
	
	make_bcat_json_dir(){
		bsv_bcatjson_d="bcat_data"
		if [[ ! -d "${bsv_bcatjson_d}" ]]; then
	       		mkdir "${bsv_bcatjson_d}"
		fi
		if [[ $save_raw_transactions == true ]]; then
			bsv_rawtx_dir="${bsv_bcatjson_d}/rawtx"
			if [[ ! -d "${bsv_rawtx_dir}" ]]; then
	       			mkdir "${bsv_rawtx_dir}"
			fi
		fi
	}
	
	test_manifest(){
		protocol_check_list=$(printf '%s\n' "${protocol_check_array[@]}'")
		bcat_list_file="${1}.bcat"
		if [[ -f $bcat_list_file ]]; then
			bcat_list_file="${bcat_list_file}.dup$EPOCHSECONDS"
		fi
		printf '%s\n' "${protocol_check_array[@]}'" | sed "s/[']//g" > "${bcat_list_file}"
		read_top_line(){
			head -n 1 <"$bcat_list_file"
		}
		remove_top_line(){
			sed -i '1d' "$bcat_list_file"
		}
		if [[ $(read_top_line) == 0 ]] || [[ $(read_top_line) == 00 ]]; then
				remove_top_line
		fi
		if [[ $(read_top_line) == OP_RETURN ]]; then
				remove_top_line
		fi
		bcat_protocol_arguments=$(cat "$bcat_list_file" | wc -l)
		if [[ $bcat_protocol_arguments -lt 7 ]]; then
			echo_red "error"
			echo_red "Less than 7 arguments provided to the Bcat transaction"
			script_exit
			exit 1
		fi
		bcat_part_tx_list=$(sed '1,6d' "$bcat_list_file")
		while IFS=' ' read -r line; do
			if [[ $(awk '{ print length }'<<<"$line") -ne 64 ]]; then
				echo_red "error: extra arguments found in bcat part list"
				script_exit
				exit 1
			fi
		done<<<"$bcat_part_tx_list"
		if [[ $save_bcat_list == false ]]; then
			rm "$bcat_list_file"
		fi
	}

	bash_bcat_retriever(){
#		tput_color
#		set_data_source "$1"
#		deps_checker
#		size_checker "$1"
		if [[ $save_json_manifest == true ]] \
			|| [[ $save_raw_transactions == true ]]; then
			make_bcat_json_dir
		fi
		get_bcat_script_asm "$1"
		print_manifest
		test_manifest "$1"
		bcat_part_loop
		if [[ $save_json_manifest == true ]]; then
			make_bcat_json "$1"
		fi
		script_exit
	}

	bash_bcat_retriever "$1" || script_exit
}

script_exit(){
	unset script_exit manual_datasource save_json_manifest save_raw_transactions \
		tput_coloring red blue normal green bright tput_color echo_red echo_blue \
		echo_green echo_bright set_data_source test_cli_rawtx test_tx_block_1 \
		test_woc_avail selected_datasource set_data_source size_checker \
		get_bcat_script_asm bsv_script_asm wocurl1 wocurl2 \
		woc_url get_hex bcat_asm_list_ bcat_manifest_ bcat_part_list print_manifest \
		xxdline_array manifest_array bcat_line_array name_bcat_file bcat_file_name \
		describe_file_ describe_file1 describe_file2 describe_file3 bcat_sha256sum \
		bcat_part_loop bcat_part_hex bsv_bcat_json_ sed_function make_bcat_json \
		json_txid tx_List bcatPts file_info file_size line_array json_filename \
		make_bcat_json_dir bsv_bcatjson_d bsv_rawtx_dir get_hex bash_bcat_retriever \
		protocol_check_array protocol_check_list test_manifest bcat_protocol_arguments \
		test_tx selected_datasource test_cli_rawtx concatenate_metafile_chunks \
		dependency_check input_length_check potential_index_txid \
		input_character_check prerequisite_checks describe_metafile \
		transaction_json metafile_name metafile_chunkList set_data_source \
		chunkpiece print_file_information metafile_grabber_main script_exit \
		_curl_GET get_data
}

pre_download_protocol_selector(){
	input_check "$potential_index_txid"
	set_data_source
	deps_checker
	transaction_json=$(get_data "$potential_index_txid")
	txid_datatype_checker
	if [[ $datafile_index_type == BCAT_INDEX ]]; then
		if [[ $verbose_output == true ]]; then
			echo ""
			echo "BCAT"
		fi
		bcat_retriever_function "$potential_index_txid"
	fi
	if [[ $datafile_index_type == METAFILE_INDEX ]]; then
		if [[ $verbose_output == true ]]; then
			echo ""
			echo "METAFILE"
		fi
		metafile_retriever_function "$potential_index_txid"
	fi
}

tput_color
pre_download_protocol_selector || script_exit
