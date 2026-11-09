# SardegnaParteciPA

## Piattaforma di partecipazione democratica

SardegnaParteciPA è la piattaforma di consultazione e partecipazione online promossa dalla Regione Sardegna basata su [Decidim](https://github.com/decidim/decidim) e sull’esperienza maturata sul portale di partecipazione democratica nazionale [ParteciPa](https://github.com/dipartimentofunzionepubblica/partecipa).

## Software

SardegnaParteciPA è un progetto Open-Source basato su [Decidim](https://github.com/decidim/decidim), la piattaforma di partecipazione democratica creata dalla città di Barcellona e utilizzata da numerose amministrazioni pubbliche e aziende private in tutto il mondo. Decidim è concesso in licenza attraverso la [GNU Affero General Public License v3.0](https://github.com/decidim/decidim/blob/develop/LICENSE-AGPLv3.txt).

Prima di installare e utilizzare SardegnaParteciPA raccomandiamo un attento esame della documentazione relativa a Decidim e di questo README.

Dal punto di vista tecnico Decidim è basato su:

* Framework: Ruby on Rails

* Linguaggio: Ruby

* Database: PostgreSQL

* Application Server: Passenger/Nginx

I manuali di Amministrazione per Decidim si trovano sotto il seguente URL: https://decidim.org/docs/.

Istruzioni dettagliate su come installare Decidim si trovano a [questo indirizzo](https://platoniq.github.io/decidim-install).

Le seguenti istruzioni di installazione riguardano la sola installazione o aggiornamento di SardegnaParteciPA:

1. Scaricare da GitHub:

   ```
   git clone https://github.com/regionesardegna/sardegnapartecipa
   cd sardegnapartecipa
   
   ```

2. Installare le dipendenze:

   ```
   bundle install
   
   ```

3. Precompilare gli assets:

   ```
   bundle exec rails assets:precompile
   
   ```

4. Aggiornare il database:

   ```
   bundle exec rails db:migrate
   
   ```

Vedere sotto i file di configurazione da compilare adeguatamente.

## Moduli

Decidim è articolato in più moduli che possono essere inclusi nell'applicativo opzionalmente.

Per includere un nuovo modulo occorrerà aggiungerlo al `Gemfile` (ad es. nel caso del modulo conferenze, versione 0.20.0):

```
gem "decidim-conferences", "0.20.0"

```

Per installare il nuovo modulo sarà poi necessario eseguire:

```
bundle install
bundle exec rails decidim_conferences:install:migrations
bundle exec rails db:migrate

```

## Modifiche e integrazioni di SardegnaParteciPA rispetto a Decidim

SardegnaParteciPA usa il core di Decidim e personalizza o integra solo i seguenti aspetti:

* Utilizzo del Sistema Pubblico di Identità Digitale (SPID), della Carta di Identità Elettronica (CIE) e della Tessera Sanitaria - Carta Nazionale dei Servizi (CNS) attraverso l'Access Manager di Regione Sardegna con comunicazione via SAML, tramite la gem pubblicata dal Dipartimento Funzione Pubblica `decidim-module-spid-cie`;

* Aspetto grafico ridefinito via SCSS e modifiche dei templates con customizzazioni della User Interface specifiche per SardegnaParteciPA;

* Modifiche sul profilo dell’utente per soddisfare le indicazioni del GDPR;

* Integrazione dei moduli community.

## Utilizzo del Sistema Pubblico di Identità Digitale (SPID), della Carta di Identità Elettronica (CIE) e della Carta Nazionale dei Servizi (CNS)

L'autenticazione tramite SPID, CIE e CNS su SardegnaParteciPA è gestita mediante la gem [decidim-module-spid-cie](https://github.com/dipartimentofunzionepubblica/decidim-module-spid-cie), che comunica tramite il protocollo SAML con l'Access Manager (AM) di Regione Sardegna, che ha funzione di Gateway unificato.

SardegnaParteciPA richiede per il suo utilizzo due soli attributi utente: l'Indirizzo di posta elettronica e il Codice Fiscale. La piattaforma non memorizza in alcun modo le credenziali SPID, CIE o CNS dell'utente; vengono tracciati in un apposito log contenuto nel Database gli eventi di registrazione, login e logout dell'utente. SardegnaParteciPA utilizza tutte le raccomandazioni prescritte da SPID, CIE o CNS per garantire la massima sicurezza nelle transazioni.

Per abilitare il login SPID/CIE/CNS alla piattaforma, essa deve essere configurata adeguatamente.
È indispensabile che sia configurato il file `<sardegnapartecipa_path>/config/application.yml` che contiene le informazioni essenziali per il sistema, si veda sotto per maggiori dettagli.

Il file `secrets.yml` funge da collettore di tutte le costanti importandole da `application.yml` e non deve essere editato.
Si rimanda al `README.md` della gem [decidim-module-spid-cie](https://github.com/dipartimentofunzionepubblica/decidim-module-spid-cie) per i dettagli relativi alla configurazione del sistema.

## Aspetto grafico ridefinito via SCSS e modifiche dei templates

L'aspetto grafico di SardegnaParteciPA è stato ridefinito applicando una serie di customizzazioni alla User Interface dedicate, rispettando le indicazioni contenute nelle linee guida di usabilità e accessibilità per i siti e le applicazioni della PA.

## Modifiche sul profilo dell’utente per soddisfare le indicazioni del GDPR

Come ParteciPa, SardegnaParteciPA utilizza il modulo del Dipartimento Funzione Pubblica [Decidim-Privacy](https://github.com/dipartimentofunzionepubblica/decidim-module-privacy) per meglio salvaguardare la privacy dei partecipanti ai processi di consultazione al fine di soddisfare al meglio le indicazioni italiane per l’applicazione del GDPR:

* Rimozione della possibilità per l’utente di caricare avatar personalizzato;

* Eliminazione della visibilità pubblica del profilo Utente;

* Rimozione della funzionalità che permette di "seguire" un Utente;

* Rimozione della funzionalità di ricerca di un Utente e dei Commenti;

* Rimozione della possibilità di contattare gli Utenti;

* Rimozione della ricercabilità su Google del profilo Utente.

## Integrazione dei moduli community

Decidim utilizza un sistema centralizzato di definizione della localizzazione della piattaforma attraverso [Crowdin](https://crowdin.com) nel quale le traduzioni sono applicabili indistintamente a tutte le istanze della piattaforma nella lingua data.
Il modulo community [Term-Customizer](https://github.com/mainio/decidim-module-term_customizer) può essere utilizzato per creare traduzioni applicabili alla sola istanza della piattaforma che si sta utilizzando.
Il modulo community [Decidim-Awesome](https://github.com/Platoniq/decidim-module-decidim_awesome) fornisce un set di funzionalità avanzate che riguardano vari aspetti delle consultazioni.

## application.yml

Il file `<sardegnapartecipa_path>/config/application.yml` contiene le principali configurazioni indispensabili per il funzionamento dell'applicativo.
La creazione e la redazione del file è a cura di chi installa la piattaforma secondo le indicazioni sotto; il file non è compreso nel repository.
Tutte le costanti vengono trasformate in stringhe dalla gem Figaro che le legge. I tipi di dato indicati sotto (Stringa, Booleano, Intero, ecc.) servono ad orientare chi redige il file.

```
SECRET_KEY_BASE: # Stringa, secret key utilizzata da Rails per il suo funzionamento (vedere https://medium.com/@michaeljcoyne/understanding-the-secret-key-base-in-ruby-on-rails-ce2f6f9968a1)
HOST: # Stringa, nome dell'host
PROTOCOL: # Stringa, normalmente "https"

# Costanti relative a Matomo. In caso manchino, lo script non verrà eseguito
MATOMO_URL: # Stringa, URL istanza Matomo se presente
MATOMO_ID: # Stringa, ID Matomo se presente

DATABASE_URL: # Stringa, URL del DB nella forma "postgres://<DATABASE_USERNAME>:<DATABASE_PASSWORD>@<DATABASE_HOST>/<DATABASE_NAME>"
DATABASE_HOST: # Stringa, Host che ospita il DB
DATABASE_USERNAME: # Stringa, username del DB
DATABASE_PASSWORD: # Stringa, password del DB

SMTP_USERNAME: # Stringa, username dell'account di posta utilizzato per la spedizione delle mail via SMTP
SMTP_PASSWORD: # Stringa, password dell'account di posta
SMTP_ADDRESS: # Stringa, indirizzo dell'SMTP
SMTP_DOMAIN: # Stringa, dominio dell'SMTP
SMTP_PORT: # Intero, porta SMTP
SMTP_STARTTLS_AUTO: # Booleano, abilitazione STARTTLS
SMTP_AUTHENTICATION: # Stringa, tipo di autenticazione SMTP ("plain", "login")
SMTP_OPENSSL_VERIFY_MODE: # Booleano, modalità di verifica OpenSSL
SMTP_SSL: # Booleano, abilitazione SSL
SMTP_TLS: # Booleano, abilitazione TLS
SMTP_OPEN_TIMEOUT: # Intero, timeout apertura connessione SMTP in secondi
SMTP_READ_TIMEOUT: # Intero, timeout lettura SMTP in secondi

GEOCODER_LOOKUP_APP_ID: # Stringa, app ID per geocoding
GEOCODER_LOOKUP_APP_CODE: # Stringa, app code per geocoding
GEOCODER_API_KEY: # Stringa, API key per geocoding

# Costanti relative alle configurazioni di SPID, CIE, CNS tramite gateway AM Regione Sardegna.
# Per approfondimenti: https://github.com/dipartimentofunzionepubblica/decidim-module-spid-cie
SPID_TENANT_NAME: # Stringa, nome del tenant SPID (se non valorizzata l'initializer non verrà istanziato)
SPID_BUTTON_SIZE: # Stringa, dimensione del bottone SPID ("s", "m", "l", "xl")
SPID_ENTITY_ID: # Stringa, entity ID del Service Provider
SPID_METADATA_PATH: # Stringa, percorso dei metadati SPID
SPID_SIGNATURE_METHOD: # Stringa, metodo di firma SPID ("256", "384")
SPID_DEFAULT_ACS_INDEX: # Intero, indice ACS di default
SPID_ACS_INDEX: # Intero, indice ACS
SPID_SLO_INDEX: # Intero, indice SLO
SPID_ATTR_SERV_LIST_INDEX: # Intero, indice attributi
SPID_LEVEL: # Intero, livello SPID richiesto (1, 2 o 3)
SPID_ORGANIZATION_NAME: # Stringa, nome organizzazione SPID
SPID_ORGANIZATION_DISPLAY_NAME: # Stringa, nome visualizzato organizzazione
SPID_ORGANIZATION_URL: # Stringa, URL organizzazione
SPID_CONTACT_PERSON_IPA_CODE: # Stringa, codice IPA persona di contatto
SPID_CONTACT_PERSON_VAT_NUMBER: # Stringa, partita IVA persona di contatto
SPID_CONTACT_PERSON_FISCAL_CODE: # Stringa, codice fiscale persona di contatto
SPID_CONTACT_PERSON_GIVEN_NAME: # Stringa, nome persona di contatto
SPID_CONTACT_PERSON_EMAIL: # Stringa, email persona di contatto
SPID_CONTACT_PERSON_COMPANY: # Stringa, azienda persona di contatto
SPID_CONTACT_PERSON_NUMBER: # Stringa/Intero, numero di telefono persona di contatto
SPID_PRIVATE_KEY: # Stringa, path chiave privata SPID
SPID_CERTIFICATE: # Stringa, path certificato SPID
SPID_ACS_LOCATION_PROD: # Stringa, URL ACS produzione (es. URL produzione + "/spid/samlsso")
SPID_ACS_LOCATION_DEMO: # Stringa, URL ACS demo (es. URL demo + "/spid/samlsso")
SPID_ACS_LOCATION_DEV: # Stringa, URL ACS sviluppo (es. URL sviluppo + "/spid/samlsso")
SPID_ACS_LOCATION_STAGING: # Stringa, URL ACS staging (es. URL staging + "/spid/samlsso")
SPID_ACS_BINDING_PROD: # Stringa binding ACS produzione ("urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" o "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect")
SPID_ACS_BINDING_DEMO: # Stringa binding ACS demo
SPID_ACS_BINDING_DEV: # Stringa binding ACS sviluppo
SPID_ACS_BINDING_STAGING: # Stringa binding ACS staging
SPID_SLO_LOCATION_PROD: # Stringa, URL SLO produzione (es. URL produzione + "/spid/samlslo")
SPID_SLO_LOCATION_DEMO: # Stringa, URL SLO demo
SPID_SLO_LOCATION_DEV: # Stringa, URL SLO sviluppo
SPID_SLO_LOCATION_STAGING: # Stringa, URL SLO staging
SPID_SLO_BINDING_PROD: # Stringa binding SLO produzione
SPID_SLO_BINDING_DEMO: # Stringa binding SLO demo
SPID_SLO_BINDING_DEV: # Stringa binding SLO sviluppo
SPID_SLO_BINDING_STAGING: # Stringa binding SLO staging
SPID_SLO_RESPONSE_LOC_PROD: # Stringa, URL di ritorno a seguito di Logout in produzione
SPID_SLO_RESPONSE_LOC_DEMO: # Stringa, URL di ritorno a seguito di Logout in demo
SPID_SLO_RESPONSE_LOC_DEV: # Stringa, URL di ritorno a seguito di Logout in sviluppo
SPID_SLO_RESPONSE_LOC_STAGING: # Stringa, URL di ritorno a seguito di Logout in staging

# Configurazioni di Decidim
DECIDIM_APPLICATION_NAME: # Stringa, nome dell'applicativo
DECIDIM_MAILER_SENDER: # Stringa, indirizzo email mittente
DECIDIM_AVAILABLE_LOCALES: # Stringa, locales attivati nell'istanza (es. "en, it")
DECIDIM_DEFAULT_LOCALE: # Stringa, locale di default (es. "it")
DECIDIM_FORCE_SSL: # Stringa, forzatura SSL ("auto", "true", "false")
DECIDIM_ENABLE_HTML_HEADER_SNIPPETS: # Booleano, abilita header snippets JS da dashboard
DECIDIM_CURRENCY_UNIT: # Stringa, divisa monetaria di default (es. "€")
DECIDIM_CORS_ENABLED: # Booleano, abilita CORS
DECIDIM_IMAGE_UPLOADER_QUALITY: # Intero, qualità immagini uploader (es. 80)
DECIDIM_MAXIMUM_ATTACHMENT_SIZE: # Intero, dimensione massima allegati in MB
DECIDIM_MAXIMUM_AVATAR_SIZE: # Intero, dimensione massima avatar in MB
DECIDIM_MAX_REPORTS_BEFORE_HIDING: # Intero, soglia segnalazioni prima del blocco contenuto
DECIDIM_TRACK_NEWSLETTER_LINKS: # Stringa, configurazione tracciamento link newsletter tramite UTM
DECIDIM_DOWNLOAD_YOUR_DATA_EXPIRY_TIME: # Intero, giorni di disponibilità del download dati sul server
DECIDIM_THROTTLING_MAX_REQUESTS: # Intero, numero massimo di richieste per IP nell'unità di tempo
DECIDIM_THROTTLING_PERIOD: # Intero, unità di tempo in minuti per il conteggio throttling
DECIDIM_UNCONFIRMED_ACCESS_FOR: # Intero, giorni di accesso consentiti senza conferma email
DECIDIM_SYSTEM_ACCESSLIST_IPS: # Stringa, elenco IP o subnet autorizzati ad accedere a /system
DECIDIM_BASE_UPLOADS_PATH: # Stringa, base path per gli caricamenti
DECIDIM_DEFAULT_CSV_COL_SEP: # Stringa, separatore colonne per i file CSV
DECIDIM_CONSENT_COOKIE_NAME: # Stringa, nome cookie per memorizzare il consenso GDPR
DECIDIM_CACHE_KEY_SEPARATOR: # Stringa, separatore chiave cache
DECIDIM_EXPIRE_SESSION_AFTER: # Intero, minuti per scadenza sessione
DECIDIM_SESSION_TIMEOUT_INTERVAL: # Intero, minuti per conferma presenza utente
DECIDIM_ENABLE_REMEMBER_ME: # Stringa, abilita "Ricordati di me" ("auto", "true", "false")
DECIDIM_FOLLOW_HTTP_X_FORWARDED_HOST: # Stringa, opzione di configurazione HTTP_X_FORWARDED_HOST
DECIDIM_MAXIMUM_CONVERSATION_MESSAGE_LENGTH: # Intero, numero massimo caratteri per messaggio
DECIDIM_PASSWORD_BLACKLIST: # Stringa, lista di parole non consentite nelle password
DECIDIM_ALLOW_OPEN_REDIRECTS: # Booleano, disabilita il redirect ad un altro host
DECIDIM_SERVICE_WORKER_ENABLED: # Booleano, abilita/disabilita Service Worker
DECIDIM_ADMIN_PASSWORD_EXPIRATION_DAYS: # Intero, giorni di scadenza password admin
DECIDIM_ADMIN_PASSWORD_MIN_LENGTH: # Intero, lunghezza minima password admin
DECIDIM_ADMIN_PASSWORD_REPETITION_TIMES: # Intero, numero di password precedenti da memorizzare
DECIDIM_ADMIN_PASSWORD_STRONG: # Booleano, attiva le regole per la password strong
API_SCHEMA_MAX_PER_PAGE: # Intero, elementi massimi restituiti da una query GraphQL
API_SCHEMA_MAX_COMPLEXITY: # Intero, complessità massima query GraphQL
API_SCHEMA_MAX_DEPTH: # Intero, profondità massima innesto query GraphQL
PROPOSALS_SIMILARITY_THRESHOLD: # Float, soglia di similarità proposta
PROPOSALS_SIMILARITY_LIMIT: # Intero, limite di similarità proposta
PROPOSALS_PARTICIPATORY_SPACE_HIGHLIGHTED_PROPOSALS_LIMIT: # Intero, proposte evidenziate nello spazio partecipativo
PROPOSALS_PROCESS_GROUP_HIGHLIGHTED_PROPOSALS_LIMIT: # Intero, limite proposte evidenziate nel gruppo di processi
MEETINGS_UPCOMING_MEETING_NOTIFICATION: # Intero, giorni preavviso notifiche meeting imminenti
MEETINGS_ENABLE_PROPOSAL_LINKING: # Booleano, abilita collegamento proposte nei meeting
MEETINGS_EMBEDDABLE_SERVICES: # Stringa, servizi integrabili nei meeting
BUDGETS_ENABLE_PROPOSAL_LINKING: # Booleano, abilita collegamento proposte nei bilanci
ACCOUNTABILITY_ENABLE_PROPOSAL_LINKING: # Booleano, abilita collegamento proposte nell'accountability
CONSULTATIONS_STATS_CACHE_EXPIRATION_TIME: # Intero, minuti di cache delle statistiche consultazioni
INITIATIVES_CREATION_ENABLED: # Booleano/Stringa, abilita la creazione delle iniziative
INITIATIVES_SIMILARITY_THRESHOLD: # Float, soglia di similarità iniziative
INITIATIVES_SIMILARITY_LIMIT: # Intero, limite di similarità iniziative
INITIATIVES_MINIMUM_COMMITTEE_MEMBERS: # Intero, numero minimo membri comitato
INITIATIVES_DEFAULT_SIGNATURE_TIME_PERIOD_LENGTH: # Intero, periodo di tempo di default per la raccolta firme (giorni)
INITIATIVES_DEFAULT_COMPONENTS: # Stringa, componenti di default delle iniziative
INITIATIVES_FIRST_NOTIFICATION_PERCENTAGE: # Intero, percentuale completamento prima notifica
INITIATIVES_SECOND_NOTIFICATION_PERCENTAGE: # Intero, percentuale completamento seconda notifica
INITIATIVES_STATS_CACHE_EXPIRATION_TIME: # Intero, minuti di cache delle statistiche iniziative
INITIATIVES_MAX_TIME_IN_VALIDATING_STATE: # Intero, tempo massimo (giorni) in stato di validazione
INITIATIVES_PRINT_ENABLED: # Booleano/Stringa, abilita stampa iniziative
INITIATIVES_DO_NOT_REQUIRE_AUTHORIZATION: # Booleano, definisce se le iniziative non richiedono autenticazione
VERIFICATIONS_DOCUMENT_TYPES: # Stringa, tipi documenti abilitati alla verifica
ELECTIONS_BULLETIN_BOARD_SERVER: # Stringa, URL del Bulletin Board Server per le elezioni
STORAGE_PROVIDER: # Stringa, storage provider utilizzato
OMNIAUTH_FACEBOOK_APP_ID: # Stringa, App ID per OmniAuth Facebook
OMNIAUTH_TWITTER_API_KEY: # Stringa, API Key per OmniAuth Twitter
OMNIAUTH_GOOGLE_CLIENT_ID: # Stringa, Client ID per OmniAuth Google

BREADCRUMB_TRUNCATE_AFTER_WORDS: # Intero, troncamento breadcrumb dopo N parole
SURVEYS_NOTIFICATION_BCC_ADDRESS: # Stringa, indirizzo email BCC per notifiche dei sondaggi agli amministratori

```

## Segnalazioni sulla sicurezza

SardegnaParteciPA utilizza tutte le raccomandazioni e le prescrizioni in materia di sicurezza previste da Decidim e dall’Agenzia per l'Italia Digitale (AgID) per SPID. Per segnalazioni su possibili falle nella sicurezza del software riscontrate durante l'utilizzo preghiamo di usare il canale di comunicazione confidenziale attraverso l'indirizzo email supportosardegnapartecipa@sardegnait.it e non aprire segnalazioni pubbliche. È indispensabile contestualizzare e dettagliare con la massima precisione le segnalazioni. Le segnalazioni anonime o non sufficientemente dettagliate non potranno essere verificate.

## SardegnaParteciPA

Le integrazioni e le personalizzazioni di SardegnaParteciPA che modificano Decidim sono state sviluppate per la Regione Sardegna. Per contatti e informazioni scrivere a sardegnapartecipa@regione.sardegna.it. Per supporto tecnico scrivere a supportosardegnapartecipa@sardegnait.it.