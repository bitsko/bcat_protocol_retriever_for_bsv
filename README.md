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
