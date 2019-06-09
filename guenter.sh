#!/bin/bash

set -x

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# predisponi cartella dati
mkdir -p "$folder"/dati
cd "$folder"/dati/
rm -rf *

# scarica dati elettorali
curl -L "https://dait.interno.gov.it/documenti/europee2019_scrutini_area_italia.csv" -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)' >"$folder"/dati/europee2019_scrutini_area_italia.csv

# scarica elenco codici statistici dei comuni di ISTAT
wget -O "$folder"/dati/Elenco-codici-statistici-e-denominazioni-delle-unita-territoriali.zip "https://www.istat.it/storage/codici-unita-amministrative/Elenco-codici-statistici-e-denominazioni-delle-unita-territoriali.zip"

# unzippa i dati ISTAT
cd "$folder"/dati/
unzip ./"Elenco-codici-statistici-e-denominazioni-delle-unita-territoriali.zip"

cd "$folder"

# converti l'encoding dei dati elettorali in UTF-8
iconv -f 850 -t UTF-8 "$folder"/dati/europee2019_scrutini_area_italia.csv >"$folder"/dati/europee2019_scrutini_area_italia_utf8.csv

# converti l'encoding dei dati ISTAT in UTF-8
iconv -f Windows-1252 -t UTF-8 "$folder/dati/Elenco codici statistici e denominazioni delle unita territoriali/Elenco-codici-statistici-e-denominazioni-al-15_05_2019.csv" >"$folder"/dati/tmp_ISTAT.csv

# crea copia RAW dei dati anagrafici UTF-8
mlr --csv --ifs ";" cut -f REGIONE,COMUNE then uniq -a "$folder"/dati/europee2019_scrutini_area_italia_utf8.csv >"$folder"/dati/raw_anagraficaElezioni.csv
mlr --csv --ifs ";" then cut -f "Codice Comune formato alfanumerico","Denominazione in italiano","Denominazione regione" "$folder"/dati/tmp_ISTAT.csv >"$folder"/dati/raw_ISTAT.csv
# csvmatch -i "$folder"/dati/raw_ISTAT.csv "$folder"/dati/raw_anagraficaElezioni.csv --fields1 "Denominazione regione" "Denominazione in italiano" --fields2 "REGIONE" "COMUNE" --output 1."Codice Comune formato alfanumerico" 2.REGIONE 2.COMUNE --join right-outer >"$folder"/dati/steleElettoralePartenza.csv

# modifica il separatore del CSV dei dati elettorali da ";" a "," e rimuovi eventuali spazi bianchi in più
mlr -I --csv --ifs ";" cat "$folder"/dati/europee2019_scrutini_area_italia_utf8.csv

# modifica il separatore del CSV dei dati ISTAT da ";" a ",", rimuovi eventuali spazi bianchi in più, ed estrai soltanto alcune colonne
mlr --csv --ifs ";" cut -f "Codice Comune formato alfanumerico","Denominazione in italiano","Denominazione regione" "$folder"/dati/tmp_ISTAT.csv >"$folder"/dati/ISTAT.csv

# nei dati ISTAT suddividi in più colonne i nomi di regione in più lingue
mlr --csv nest --explode --values --across-fields -f "Denominazione regione" --nested-fs "/" then unsparsify "$folder"/dati/ISTAT.csv >"$folder"/dati/anagraficaISTAT.csv
# rimuovi file temporaneo
rm "$folder"/dati/tmp_ISTAT.csv

# estrai per valori univoci, dai dati elettorali, le colonne REGIONE,COMUNE
mlr --csv cut -f REGIONE,COMUNE then uniq -a "$folder"/dati/europee2019_scrutini_area_italia_utf8.csv >"$folder"/dati/anagraficaElezioni.csv

# nei dati elettorali suddividi in più colonne i nomi di comune in più lingue
mlr -I --csv nest --explode --values --across-fields -f COMUNE --nested-fs "/" then unsparsify "$folder"/dati/anagraficaElezioni.csv

csvmatch -i -a -n -l "$folder"/risorse/rule.txt "$folder"/dati/anagraficaISTAT.csv "$folder"/dati/anagraficaElezioni.csv --fields1 "Denominazione regione_1" "Denominazione in italiano" --fields2 "REGIONE" "COMUNE_1" --output 1."Codice Comune formato alfanumerico" 2.REGIONE 2.COMUNE_1 --join right-outer >"$folder"/dati/steleElettorale.csv

# rimuovi righe vuote
sed -i '/^$/d' "$folder"/dati/steleElettorale.csv

# associa i codici ISTAT ai comuni problematici
mlr -I --csv put -S '
if (${COMUNE_1} == "PUEGNAGO DEL GARDA") {
  ${Codice Comune formato alfanumerico} = "017158"
} elif (${COMUNE_1} == "SAN DORLIGO DELLA VALLE-DOLINA") {
  ${Codice Comune formato alfanumerico} = "032004"
} elif (${COMUNE_1} == "ACQUARICA DEL CAPO" || ${COMUNE_1} == "PRESICCE") {
  ${Codice Comune formato alfanumerico} = "075098"
}
' then sort -f REGIONE,"Codice Comune formato alfanumerico",COMUNE_1 "$folder"/dati/steleElettorale.csv

# sposta nella cartella principale
mv "$folder"/dati/steleElettorale.csv "$folder"/steleElettorale.csv

# rinomina i campi
sed -i -r 's/^Codice Comune for.+/codiceComuneISTAT,nomeRegione,nomeComune/g' "$folder"/steleElettorale.csv
