# Kura - Guida all'Installazione e all'Uso

Benvenuto nella **Kura**, l'applicazione ideata per supportare i curatori (amministratori di sostegno) nella gestione giornaliera delle attività, nel calcolo delle ore lavorate e nel rimborso spese per i propri pupilli.
Questa guida ti spiegherà in modo semplice come scaricare l'applicazione sul tuo computer o sul tuo telefono Android e come utilizzarla passo dopo passo.

---

## 📦 Come Scaricare e Installare l'Applicazione
Puoi scaricare l'applicazione direttamente dalla pagina **Releases** del progetto su GitHub.

### 💻 Installazione su Windows (Computer PC)
1. Vai sulla pagina GitHub del progetto e apri la sezione **Releases** (sulla destra).
2. Sotto l'ultima versione disponibile, clicca sul file **`Kura_Windows.zip`** per scaricarlo.
3. Una volta completato il download, fai clic con il tasto destro sul file scaricato e seleziona **Estrai tutto** (scegli una cartella comoda, ad esempio sul Desktop).
4. Apri la cartella estratta e fai doppio clic sul file **`Kura.exe`** per avviare l'applicazione.
   *(Nota: Se Windows mostra un avviso di sicurezza "PC protetto da Windows Defender", clicca su "Ulteriori informazioni" e poi su "Esegui comunque").*

### 📱 Installazione su Android (Telefono)
1. Dal browser del tuo telefono Android, apri la pagina delle **Releases** di GitHub del progetto.
2. Clicca sul file **`Kura_Android.apk`** per scaricarlo.
3. Al termine del download, clicca sul file scaricato per installarlo.
   - Se è la prima volta che installi un'app da internet, il telefono ti chiederà di abilitare l'opzione **"Consenti installazione da sorgenti sconosciute"** (generalmente per il browser Chrome). Segui le istruzioni a schermo per abilitarla.
4. Completa l'installazione e troverai l'icona dell'applicazione nella schermata principale del tuo telefono.
---
## 📖 Manuale d'Uso dell'Applicazione
### 1. Primo Accesso e Registrazione
- **Registrazione (Signup)**: Se è la prima volta che usi l'app, clicca su "Registrati", inserisci la tua email, una password a tua scelta e il tuo **Nome e Cognome** (quest'ultimo verrà usato per firmare i report PDF).
- **Accesso Persistente**: Una volta effettuato l'accesso, l'applicazione si ricorderà di te. Non dovrai inserire la password ogni volta che la apri. Per motivi di sicurezza, ti verrà chiesto di inserire nuovamente la password solo una volta ogni 7 giorni.
---
### 2. Gestione dei Pupilli (La Schermata Principale)
La schermata iniziale mostra l'elenco dei tuoi pupilli attualmente seguiti.
- **Aggiungere un Pupillo**: Se la lista è vuota, clicca sul pulsante "Aggiungi il tuo primo pupillo". Inserisci:
  - Il **Nome** del pupillo.
  - Il **Budget massimo di ore** concordato all'anno.
  - La **Tariffa oraria** (in CHF).
  - La **Tariffa chilometrica** per i rimborsi di viaggio (in CHF).
- **Progresso Visivo**: Sotto il nome di ciascun pupillo vedrai una barra colorata che mostra a colpo d'occhio quante ore hai già lavorato nell'**anno corrente** rispetto al budget massimo disponibile, e quante ore rimangono libere.
---
### 3. Registrazione di una Nuova Attività (Prestazione)
Cliccando su un pupillo nella pagina principale, entrerai nel suo dettaglio dove potrai premere il pulsante **"Aggiungi Attività"**.
Nel modulo che si aprirà, puoi registrare la prestazione compilando i campi:
- **Data**: Impostata automaticamente su oggi, ma modificabile cliccando sul calendario.
- **Tipo di Attività**: Scegli tra *Telefonata, Trasferta, Lettera/Email, Incontro con il Pupillo, Incontro Varie o Altro*.
- **Campi dinamici a seconda della scelta**:
  - Se selezioni **Trasferta**: l'app ti chiederà di inserire sia il **tempo impiegato** (in ore) che i **chilometri percorsi** (km).
  - Se selezioni **Lettera/Email**: potrai inserire il tempo impiegato e l'eventuale **costo del francobollo** (in CHF).
  - Per gli altri tipi di attività (es: Telefonata, Incontri), dovrai inserire solo il **tempo impiegato** (in ore).
- **Descrizione / Note**: Uno spazio in cui inserire note dettagliate sull'attività svolta (es. "Colloquio telefonico con il medico curante").
---
### 4. Statistiche e Calcolo dei Rimborsi
Cliccando sull'icona del grafico (in alto a destra nella schermata principale), accedi alle **Statistiche Interattive**:
- **Seleziona il Pupillo**: Scegli di quale pupillo analizzare i dati.
- **Filtro Temporale**: Scegli se vedere i dati di un **singolo Giorno**, di un **Mese** specifico o di un intero **Anno**.
- **Ordinamento**: Clicca sul pulsante freccia ($\uparrow$/$\downarrow$) per ordinare le prestazioni dalle più recenti alle più vecchie, o viceversa.
- **Dettaglio**: Puoi cliccare su una singola prestazione nell'elenco in basso per vederne i dettagli completi o rileggere le note associate.
---
### 5. Esportazione e Stampa del Report PDF (Fattura)
Sempre nella schermata delle Statistiche, dopo aver impostato il filtro desiderato (es. *Pupillo Mario Rossi*, *Mese di Luglio 2026*), apparirà in alto a destra un'icona con il simbolo del PDF.
Cliccando sul pulsante **Esporta PDF**:
1. L'app contatterà in modo sicuro il server per generare un documento PDF formattato in formato A4.
2. Il PDF calcolerà automaticamente per te il **Riepilogo Finanziario in CHF**:
   - Totale delle ore lavorate moltiplicato per la tariffa oraria.
   - Totale dei km percorsi moltiplicato per la tariffa chilometrica.
   - Totale della spesa per i francobolli cartacei.
   - **Totale complessivo da fatturare**.
3. Il documento conterrà anche il riassunto visivo delle ore divise per categoria e la tabella cronologica dettagliata di tutte le prestazioni.
4. Al termine del caricamento, si aprirà la schermata di stampa del tuo PC o del tuo telefono. Da qui potrai **stampare direttamente il foglio** oppure **inviarlo via email o WhatsApp** (ad esempio al tribunale o ai familiari) senza occupare memoria sul dispositivo.
---
### 6. Impostazioni (Zona Sicurezza)
Cliccando sull'icona dell'ingranaggio in alto a destra, accedi alle Impostazioni:
- **Cambia Nome**: Modifica il tuo nome e cognome curatore (che compare nelle intestazioni dei PDF).
- **Elimina Pupillo**: Rimuove un pupillo e tutte le sue attività associate. Trattandosi di un'azione critica, l'applicazione ti chiederà di **confermare la scelta due volte di seguito**.
- **Elimina Profilo**: Cancella definitivamente il tuo account e tutti i dati registrati. Per evitare cancellazioni accidentali, l'applicazione ti costringerà a **digitare manualmente la parola "ELIMINA"** prima di procedere.
