- [Creare in pochi minuti una mappa elettorale a partire dai dati del ministero dell'Interno](#creare-in-pochi-minuti-una-mappa-elettorale-a-partire-dai-dati-del-ministero-dellinterno)
  - [I dati](#i-dati)
  - [Problemi](#problemi)
  - [Note](#note)
- [Lo script](#lo-script)

# Creare in pochi minuti una mappa elettorale a partire dai dati del ministero dell'Interno

Qualche giorno fa mi ha scritto Guenter Richter - anzi lo scrivo bene **Güenter** Richter, perché gli accenti contano - per chiedermi se quest'anno onData avesse fatto qualcosa con i dati elettorali delle elezioni europee del 26 maggio 2019.<br>Lo chiede perché diverse volte abbiamo fatto dei lavori di *scraping*, pulizia e noralizzazione sui dati elettorali ([quello sulle politiche del 2018](https://github.com/ondata/elezionipolitiche2018#sitografia) è stato fonte ci circa 15 pubblicazioni); ma questa volta purtroppo non abbiamo lavorato su questi dati.

Però nella vita precedente facevo più mappe e visto che non era necessario fare lo *scraping* ([i dati aperti sono pubblicati](https://twitter.com/Viminale/status/1135550843841916928)) e che Güenter mi aveva raccontato di avere fatto queste belle mappe di sotto, ho deciso di farla anche io una "mappetta". Uso questo termine perché volevo fare una cosa carina di base (il partito più votato per ogni comune), in pochi minuti.

E confermo che **per fare la mappa, ci vuole poco tempo**. A seguire le modalità scelte.

## I dati

Il primo passo è stato quello di scaricare il file ["Europee 2019. Scrutini Area Italia"](https://dait.interno.gov.it/documenti/europee2019_scrutini_area_italia.csv) pubblicato su [Eligendo](https://dait.interno.gov.it/elezioni/open-data/dati-elezioni-europee-26-maggio-2019).
<br>Prima di aprirlo ho voluto verificare sul sito quale fosse l'***encoding*** scelto e il **separatore dei campi** del CSV.

---

⚠️ Di *encoding* e separatore non c'è traccia sul sito del Ministero degli Interni.

---

Il separatore si legge guardando le prime righe del file (`I : ITALIA NORD-OCCIDENTALE;LIGURIA;GENOVA;ARENZANO;PARTITO DEMOCRATICO;1904`) ed qui è il carattere `;`. Per l'*encoding* ho usato uno dei tool con cui si ricava via *inferencing* ([chardet](https://github.com/chardet/chardet)); ho avuto una brutta sorpresa (la prima volta che mi succede), perché lo strumento non è stato in grado di estrarla. E anche con altri strumenti non riesco a risolvere, perché ho sempre caratteri illegibili, come sotto (avviene ad esempio per tutti i nomi in tedesco con dieresi, del Trentino-Alto Adige).

    ITALIA NORD-ORIENTALE;TRENTINO-ALTO ADIGE;BOLZANO;LUSON/LۓEN;SVP;506

Allora ho fatto una cosa molto grezza e "manuale": ho aperto il CSV con LibreOffice Calc, e provato uno ad uno il set di caratteri, finché in anteprima mi è comparsa la `Ü` di LÜSEN (e anche di Güenter). Perché gli accenti sono importanti.

![](https://i.imgur.com/S8YMhfv.png)

L'*encoding* è il cosidetto [Code page 850](https://www.wikiwand.com/en/Code_page_850). <br>Questa è per me un'altra cosa mai vista.

---

⁉️ Quante mappe avrei potuto creare nel tempo che ho impiegato a scoprire quale fosse il set di caratteri ?

---

Ok, a questo avrei dovuto avere tutto: mi sarebbe bastato scaricare il file geografico con i limiti comunali e fare il *JOIN* con i dati elettorali a partire dal codice ISTAT dei vari comuni. Ma purtroppo (vedi tabella di esempio di sotto, quest'informazione non c'è).

---

⚠️ Nei dati del Ministero degli interni non c'è alcun riferimento a codici ISTAT.

---

| CIRCOSCRIZIONE | REGIONE | PROVINCIA | COMUNE | LISTA | VOTI_LISTA |
| --- | --- | --- | --- | --- | --- |
| II : ITALIA NORD-ORIENTALE | FRIULI-VENEZIA GIULIA | TRIESTE | SAN DORLIGO DELLA VALLE-DOLINA | LEGA SALVINI PREMIER | 805 |
| II : ITALIA NORD-ORIENTALE | TRENTINO-ALTO ADIGE | BOLZANO | LUSON/LÜSEN | +EUROPA - ITALIA IN COMUNE - PDE ITALIA | 90 |
| IV : ITALIA MERIDIONALE | PUGLIA | LECCE | PRESICCE | FORZA ITALIA | 205 |
| V : ITALIA INSULARE | SICILIA | MESSINA | GIARDINI NAXOS | FORZA ITALIA | 548 |
| V : ITALIA INSULARE | SICILIA | PALERMO | CEFALU' | MOVIMENTO 5 STELLE | 1186 |

Avere il codice ISTAT sarebbe stata la cosa più comoda, ma mi sono detto "Andrea, usa i nomi dei comuni, ma occhio, in Italia ci sono **comuni con lo stesso nome**".
<br>Ho allora scaricato da [ISTAT](https://www.istat.it/it/archivio/6789) i "[Codici statistici delle unità amministrative territoriali: comuni, città metropolitane, province e regioni](https://www.istat.it/storage/codici-unita-amministrative/Elenco-codici-statistici-e-denominazioni-delle-unita-territoriali.zip)" aggiornati al 15 maggio 2019.
<br>Prima di aprirlo ho voluto verificare sul sito di ISTAT quale fosse l'***encoding*** scelto e il **separatore dei campi** del CSV.

---

⚠️ Di *encoding* e separatore non c'è traccia nemmeno sul sito di ISTAT.

---

Ripeto allora quanto fatto sopra sul tema: per fortuna qui l'analisi automatica mi mappa correttamente l'*encoding*, che stavolta è `Windows-1252`.

Allora potevo iniziare con i *JOIN* per nome del Comune e Regione (infatti in una regione non possono esserci comuni con lo stesso nome). Lo faccio e ottengo **ZERO coincidenze**.
<br>Colpa mia, fatto di fretta: **nel file del Ministero degli Interni i nomi dei luoghi sono in "TUTTO MAIUSCOLO" e sul file ISTAT no**. I PC sono scemi e se non istruiti vedono "MILANO" e "Milano" come due città diverse.

---

🛎️ I nomi dei luoghi in eligendo sono in "TUTTO MAIUSCOLO"

---

Avere il *case* dei caratteri tutto in maisculo (o in minisculo), alle volte è comodo, perché stringhe come queste hanno delle problematicità che possono provocare errori: ad esempio il nome del Comune di "Terranova dei Passerini" non ha tutte le prime lettere in maiuscolo.<br>
Allora ho riportato tutto in maiscuolo e rifatto il *JOIN*: per ben **501 comuni però senza esito**.<br>
Allora ho guardato un po' l'*output* e ho visto che ad esempio tutti comuni del Trentino-Alto Adige e della Valle d'Aosta erano assenti e questo avveniva perché nel file ISTAT i nome delle Regioni sono espresse in tutte le lingue ufficiali di quella regione (quindi Valle d'Aosta/Vallée d'Aoste e Trentino-Alto Adige/Südtirol).

---

🛎️ I nomi delle regioni in questo file ISTAT sono espresse nelle lingue ufficiali relative.

---

Allora ho estratto i soli nomi in italiano delle regioni e rifatto il tutto: per diversi comuni non riescivo a fare la correlazione per nome.

## Problemi

| Nome Ministero Interni | Nome ISTAT | Note
| --- | --- | --- |
| PUEGNAGO DEL GARDA | PUEGNAGO SUL GARDA | Sono chiamati diversamente |
| SAN DORLIGO DELLA VALLE-DOLINA | SAN DORLIGO DELLA VALLE | Sono chiamati diversamente |
| ACQUARICA DEL CAPO | PRESICCE-ACQUARICA | È stato unito al Comune di Presicce e rinominato |
| PRESICCE | PRESICCE-ACQUARICA | È stato unito al Comune di Acquarica del Capo e rinominato |

## Note

In ISTAT `Borgocarbonara  ` con due spazi

# Lo script

**Güenter** mi aveva anche detto che, prima di fare la sua mappa, aveva dedicato molto tempo nel mettere in relazione le due anagrafiche. E aveva aggiunto: "voi come fate?"

Detto che l'obiettivo di base è **associare il codice ISTAT ai nomi dei Comuni usati dal Ministero degli Interni**, un flusso di lavoro potrebbe essere questo:

- scaricare i due dataset (dati elettorali e dati ISTAT con i codici di ogni Comune);
- verifcare di entrambi l'***encoding*** e riportali verso uno comune e più "standard" (come l'UTF-8);
- verifcare di entrambi il ***separatore di campo***, sceglierne uno comune e per comodità usare quello di *default* per la gran parte delle applicazioni, ovvero la `,`;
- estrarre i valori univoci di "Nome Comune in italiano", "Regione", per i dati elettorali, per creare il **file anagrafico** di base di questa risorsa;
- estrarre i valori di "Nome Comune in italiano, "Codice Comunale ISTAT", "Nome Regione in italiano", per i dati ISTAT, per creare il file anagrafico di base di questa risorsa;
- fare il ***JOIN*** per nome di Comune e Regione tra le due anagrafiche create, in modo da associare ai nomi dei Comuni dei dati elettorali il codice ISTAT
  - senza tenere conto del ***case* dei caratteri** (maiuscolo, minuscolo);
  - senza tenere conto di **spazi errati** (doppi spazi da riportare a uno e spazi a inizio/fine cella da rimuovere);
  - senza tenere conto dei **caratteri non alfanumerici** (come `-`, `~`, `.`, ecc.);
  - senza tenere conto dei **caratteri accentati** e riportali secondo l'alfabeto latino;
- **correggere** in modo specifico i **nomi dei Comuni** di cui non è possibile fare il *JOIN*, per errori presenti nei file di origine.
