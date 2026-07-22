# Gym — Allenamento a casa

App iOS nativa in **SwiftUI** per allenarsi a casa con corpo libero e attrezzi casalinghi. Compatibile **solo con iOS 26+**, design **Liquid Glass** ufficiale.

## Funzionalità

- **Oggi** — Scheda allenamento del giorno con modalità guidata full-screen, timer recupero con haptic
- **Programma** — 4 piani (Principiante/Intermedio/Avanzato + Push/Pull/Core/Cardio), modificabili
- **Esercizi** — 33 esercizi con istruzioni, errori comuni, varianti e link YouTube
- **Progressi** — Heatmap streak, grafici settimanali/mensili, note post-sessione
- **Profilo** — Obiettivi, unità di misura, promemoria, reset dati

## Requisiti

- iPhone con **iOS 26** o successivo
- **SideStore** (o AltStore) per installazione sideload
- Nessun Mac necessario — la build avviene su GitHub Actions

## Build automatica (GitHub Actions)

Ogni push su `main`/`master` o tag `v*` avvia il workflow che:

1. Compila l'archivio con `xcodebuild archive` **senza firma** (`CODE_SIGNING_ALLOWED=NO`)
2. Impacchetta l'`.ipa` unsigned in `Gym-unsigned.ipa`
3. Carica l'artifact `Gym-unsigned-ipa` (conservato 30 giorni)

### Scaricare l'IPA

1. Vai su [github.com/xSaturnMoon/gym/actions](https://github.com/xSaturnMoon/gym/actions)
2. Apri l'ultimo workflow completato con successo (segno verde)
3. Scorri fino a **Artifacts** in fondo alla pagina
4. Scarica **Gym-unsigned-ipa** (file `.zip` contenente `Gym-unsigned.ipa`)

## Installazione con SideStore

### Prerequisiti

1. **SideStore** installato su iPhone ([sidestore.io](https://sidestore.io))
2. **AltServer** in esecuzione sul PC (stessa rete Wi-Fi dell'iPhone, o via cavo USB)
3. Apple ID personale (gratuito — refresh ogni 7 giorni)

### Passaggi

1. **Trasferisci l'IPA** sul telefono:
   - Via AirDrop dal PC/Mac
   - Oppure salvalo in File su iCloud Drive e aprilo da iPhone

2. **Apri SideStore** → scheda **My Apps** → **+** (in alto a sinistra)

3. **Importa l'IPA**:
   - Seleziona `Gym-unsigned.ipa` da File
   - SideStore firmerà l'app con il tuo Apple ID (firma development/ad-hoc)

4. **Bundle ID** — l'app usa `com.xsaturnmoon.gym`:
   - Se SideStore chiede di registrare il Bundle ID, accetta
   - Puoi cambiarlo in SideStore se hai conflitti con altre app (modifica `PRODUCT_BUNDLE_IDENTIFIER` nel progetto e rifai la build)

5. **Fidati dello sviluppatore** (prima apertura):
   - Impostazioni → Generali → Gestione VPN e dispositivo
   - Seleziona il tuo Apple ID → **Autorizza**

6. **Refresh ogni 7 giorni**:
   - Apri SideStore con AltServer attivo sulla stessa rete
   - Vai su **My Apps** → tocca **Refresh All**
   - SideStore rinnova la firma development gratuita

### Note importanti

| Aspetto | Dettaglio |
|---------|-----------|
| Firma CI | L'IPA dalla GitHub Action è **unsigned** — SideStore lo firma al momento dell'import |
| Certificati | **Non servono** GitHub Secrets per certificati/profili di distribuzione |
| Scadenza | Con Apple ID gratuito l'app scade dopo **7 giorni** — refresh obbligatorio |
| iOS minimo | Solo **iOS 26.0+** — non funziona su versioni precedenti |
| Notifiche | Al primo avvio, abilita i promemoria dalla scheda Profilo |

## Struttura progetto

```
gym/
├── .github/workflows/build.yml   # CI per IPA unsigned
├── Gym.xcodeproj/
├── Gym/
│   ├── GymApp.swift
│   ├── ContentView.swift
│   ├── Models/                   # SwiftData
│   ├── Data/                     # Seed esercizi e piani
│   ├── Services/                 # Engine, timer, haptic, notifiche
│   ├── Views/                    # 5 tab + allenamento guidato
│   └── Assets.xcassets/
├── exportOptions.plist
└── README.md
```

## Personalizzare i video YouTube

Ogni esercizio ha un campo `videoURL` in `Gym/Data/ExerciseLibrary.swift`. Puoi sostituire i link con video che preferisci.

Canali consigliati per categoria:

| Categoria | Canali |
|-----------|--------|
| Petto/Spalle/Braccia | Hybrid Calisthenics, Calisthenicmovement, Athlean-X |
| Gambe/Glutei | Squat University, Bob & Brad, Hybrid Calisthenics |
| Core | Athlean-X, Calisthenicmovement, MadFit |
| Schiena | Bob & Brad, Athlean-X, FitnessFAQs |
| Cardio/HIIT | MadFit, Pamela Reif, Nobadaddiction |
| Mobilità | Bob & Brad, Squat University, Yoga With Adriene |

## Sviluppo locale (con Mac + Xcode 26)

```bash
git clone https://github.com/xSaturnMoon/gym.git
cd gym
open Gym.xcodeproj
# Seleziona un simulatore iOS 26 e premi Cmd+R
```

## Licenza

Progetto personale — uso libero per scopi personali.
