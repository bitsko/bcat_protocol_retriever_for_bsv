#!/usr/bin/env bash

get_data_function(){
	if [[ $bsv_downloader_datasource == WHATS_ON_CHAIN ]]; then
		get_data(){
			_woc_curl_GET "$1"
		}
	fi
}

_woc_curl_GET(){
        curl -s --location --request GET "https://api.whatsonchain.com/v1/bsv/main/tx/hash/${1}"
}



scriptpubkey_asm_function(){
	jq -r .vout[$1].scriptPubKey.asm<<<"$transaction_json"
}

opreturn_check(){
	while [[ $current_vout -lt $vout_count ]]; do
		check_opreturn=$(
			jq -r .vout[$current_vout].scriptPubKey.asm \
			<<<"$transaction_json"	| awk '{ print $2 }'

		)
		if [[ $verbose_mode == true ]]; then
			echo "check_opreturn $check_opreturn"
		fi
		if [[ $check_opreturn == OP_RETURN ]]; then
			opreturn_vout=$(
				jq -r .vout[$current_vout].scriptPubKey.asm \
				<<<"$transaction_json"
			)
			if [[ $verbose_mode == true ]]; then
				echo "opreturn vout: $opreturn_vout"
			fi
		fi
		current_vout=$((current_vout + 1))
	done
}

txid_datatype_checker(){
	bsv_downloader_datasource=WHATS_ON_CHAIN
	verbose_mode=false
	get_data_function
	current_vout=0
	transaction_json=$(get_data "$1")
	vout_count=$(jq '.vout | length'<<<"$transaction_json")
	opreturn_check
	potential_bcat_txid=$(
		awk '{ print $3 }'<<<"$opreturn_vout"  \
		| xxd -r -p \
		| strings
	)

	if [[ $potential_bcat_txid == 15DHFxWZJT58f9nhyGnsRBqrgwK4W6h4Up ]]; then
		echo "this is a bcat transaction"
	fi

	potential_metaid_file=$(
		awk '{ print $6 }'<<<"$opreturn_vout"  \
		|  xxd -r -p \
		| strings
	)

	if [[ $potential_metaid_file == metaid ]]; then
		echo "this is a metaid transaction"
		metaid_tx_file_type=$(
			awk '{ print $11 }'<<<"$opreturn_vout"
		)
		if [[ $metaid_tx_file_type == 6d65746166696c652f696e646578 ]]; then
			echo "this is a metfile/index transaction"
		fi
	fi
}

txid_datatype_checker "$1"
