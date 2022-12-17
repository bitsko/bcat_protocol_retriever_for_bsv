# bcat_retriever.sh

### A bash bcat retriever for the bitcoin-sv bcat protocol (concatenated bitcoin files protocol)

takes the txid of the bcat tx and creates a file from the bcat parts.

Instead of reading the mimetype, if the filetype is not part of the filename, 
will try to grep exiftool output to assign a filetype.

https://github.com/bico-media/bcat

## example:
```
$ bash bcat_retriever_bsv_node.sh  e731ca882656dd61c42d56363eaa63b585f40e1d6f18caeb0c22dec7bf8fc6c3
bcat txid: e731ca882656dd61c42d56363eaa63b585f40e1d6f18caeb0c22dec7bf8fc6c3
15DHFxWZJT58f9nhyGnsRBqrgwK4W6h4Up
image/jpeg
imagencita.png
bcat part txid: 05279a48616930ed7a6012b06bf5e3ef94ab598554b63089f7c0bb8e25079805
bcat part txid: 34601e27a630fdfb4547d581627a7f1650612e59e71c2e4741eb8a50e75ec6b2
bcat part txid: 88751b1fad284bc0e150dd5b47608383a42f8c233556a24172c20e1b88d2737d
bcat part txid: b651ca39feb2920932f916fe5c7429a907ee42171f33b40c4036770fb3786d0a
bcat part txid: ca19eb35b256299e3ef28cbc7b2993e6980d1d738065215ff0876a8abf8799cd
imagencita.png: JPEG image data, baseline, precision 8, 600x802, components 3 446K
Json manifest is located at:
bsv_bcat_json_d/e731ca882656dd61c42d56363eaa63b585f40e1d6f18caeb0c22dec7bf8fc6c3.json
```

## example json manifest 
(can be used to obtain the file in the future without the bcat manifest txid)

```
{
  "txid": "e731ca882656dd61c42d56363eaa63b585f40e1d6f18caeb0c22dec7bf8fc6c3",
  "bcat": {
    "manifest": [
      "0",
      "OP_RETURN",
      "313544484678575a4a54353866396e6879476e735242717267774b34573668345570",
      "1953719668",
      "696d6167652f6a706567",
      "0",
      "696d6167656e636974612e706e67",
      "0"
    ],
    "text": [
      "15DHFxWZJT58f9nhyGnsRBqrgwK4W6h4Up",
      "image/jpeg",
      "imagencita.png"
    ],
    "parts": [
      "05279a48616930ed7a6012b06bf5e3ef94ab598554b63089f7c0bb8e25079805",
      "34601e27a630fdfb4547d581627a7f1650612e59e71c2e4741eb8a50e75ec6b2",
      "88751b1fad284bc0e150dd5b47608383a42f8c233556a24172c20e1b88d2737d",
      "b651ca39feb2920932f916fe5c7429a907ee42171f33b40c4036770fb3786d0a",
      "ca19eb35b256299e3ef28cbc7b2993e6980d1d738065215ff0876a8abf8799cd"
    ],
    "info": "imagencita.png: JPEG image data, baseline, precision 8, 600x802, components 3",
    "size": "455924",
    "sha256sum": "ebb74774bee74b6a3b4a255f01e52985fa27904933882a538560f6da61f53dcb"
  }
}
```
## the popular paper wallet address generator resides on BSV:

```
{
  "txid": "12a4c308ea2d26afcd4104fb31b07586c38bbef8b02d78733387a8568dc9f106",
  "bcat": {
    "manifest": [
      "0",
      "OP_RETURN",
      "313544484678575a4a54353866396e6879476e735242717267774b34573668345570",
      "6164642e6269636f2e6d65646961",
      "6170706c69636174696f6e2f7a6970",
      "5554462d38",
      "626974616464726573732e6f72672d6d61737465722e7a6970",
      "0"
    ],
    "text": [
      "15DHFxWZJT58f9nhyGnsRBqrgwK4W6h4Up",
      "add.bico.media",
      "application/zip",
      "UTF-8",
      "bitaddress.org-master.zip"
    ],
    "parts": [
      "baf7e7d0b2a0d96a742539860fe3b8316fdd46c7978903ba174f2f1d5a8e38f9",
      "cecea6bbbe9b7f529414148eba55030f3641741362db9d943a885cc3037b8264",
      "6982288ddcfedcc879109d945668661d9f9bcde2c40184b67a455f233d170890",
      "ca89d595dc57ada66ce35e663446ad9ad39a509fac8b91f9e5a01269c88b7102",
      "03678f8161332bc2fb1d84ce2487c5682892147dcb3b86437462ba41a6814a8b",
      "4e2001b988c2b24ee466d3205c1d77bbc86f7c82091b31e3e1c4d7e5726824ec",
      "2b0aa8c870a0b73921e79283c1ecdcc71b51cef611af8d70dca440d829573d0f",
      "90d26b741c909078e08a818d62f12bfa68974b42c1465fd2b3c4865c6dd87057",
      "ad9dcf8112a5d539d6d78f5e0cf021ab30c0b40a6552b5dc88222e9774569e55",
      "39f313f9249ce5920a0f0e9428270602ad2a8e285ec1ed1a83d83327f2b71679"
    ],
    "info": "bitaddress.org-master.zip: Zip archive data, at least v1.0 to extract, compression method=store",
    "size": "922311",
    "sha256sum": "3c8374a8716cb5da7cb6dac9976399b12bf606da8e16c7cce97acbcdd719ff53"
  }
}
```
the hash should match this one:
```
$ wget https://github.com/pointbiz/bitaddress.org/archive/refs/heads/master.zip &>/dev/null
$ sha256sum master.zip
3c8374a8716cb5da7cb6dac9976399b12bf606da8e16c7cce97acbcdd719ff53
```
