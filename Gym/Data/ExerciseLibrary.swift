import Foundation
import SwiftData

enum ExerciseLibrary {
    static func seed(into context: ModelContext) {
        allExercises.forEach { context.insert($0) }
    }

    static let allExercises: [Exercise] = [
        // MARK: - Petto/Spalle/Braccia
        Exercise(
            id: "push-up",
            name: "Piegamenti",
            category: .chestShouldersArms,
            muscles: ["Petto", "Tricipiti", "Spalle anteriori", "Core"],
            difficulty: .beginner,
            instructions: """
            1. Parti in posizione plank con mani leggermente più larghe delle spalle.
            2. Corpo in linea retta dalla testa ai talloni, addome contratto.
            3. Abbassa il petto verso il pavimento piegando i gomiti a circa 45°.
            4. Spingi fino a estensione completa delle braccia senza bloccare i gomiti.
            """,
            commonMistakes: "Fianchi che cedono, gomiti troppo aperti (90°), testa che va in avanti, escursione incompleta.",
            videoURL: "https://www.youtube.com/watch?v=IODxDxX7oi4",
            easierVariantName: "Piegamenti sulle ginocchia",
            harderVariantName: "Piegamenti con piedi rialzati",
            equipment: ["Tappetino"],
            defaultSets: 3, defaultReps: 10, defaultRestSeconds: 60
        ),
        Exercise(
            id: "incline-push-up",
            name: "Piegamenti inclinati",
            category: .chestShouldersArms,
            muscles: ["Petto", "Tricipiti", "Spalle"],
            difficulty: .beginner,
            instructions: """
            1. Appoggia le mani su una sedia o sul bordo del divano.
            2. Corpo inclinato, piedi indietro, core attivo.
            3. Abbassa il petto verso il supporto e risali con controllo.
            """,
            commonMistakes: "Supporto troppo alto (rende l'esercizio troppo facile), schiena curva.",
            videoURL: "https://www.youtube.com/watch?v=cfns5VDVVvk",
            harderVariantName: "Piegamenti classici",
            equipment: ["Sedia"],
            defaultSets: 3, defaultReps: 12, defaultRestSeconds: 45
        ),
        Exercise(
            id: "pike-push-up",
            name: "Pike push-up",
            category: .chestShouldersArms,
            muscles: ["Spalle", "Tricipiti", "Trapezio superiore"],
            difficulty: .intermediate,
            instructions: """
            1. Posizione a V rovesciata con bacino alto e mani a terra.
            2. Piega i gomiti abbassando la testa verso il pavimento tra le mani.
            3. Spingi tornando alla posizione iniziale.
            """,
            commonMistakes: "Schiena arrotondata, gomiti che vanno troppo in fuori, escursione insufficiente.",
            videoURL: "https://www.youtube.com/watch?v=sposDXWEB0A",
            easierVariantName: "Pike push-up con mani su sedia",
            harderVariantName: "Handstand push-up a muro",
            equipment: ["Tappetino"],
            defaultSets: 3, defaultReps: 8, defaultRestSeconds: 75
        ),
        Exercise(
            id: "diamond-push-up",
            name: "Piegamenti a diamante",
            category: .chestShouldersArms,
            muscles: ["Tricipiti", "Petto interno"],
            difficulty: .intermediate,
            instructions: """
            1. Mani unite sotto il petto formando un diamante con indici e pollici.
            2. Corpo rigido in plank, gomiti vicino al corpo.
            3. Abbassa e spingi mantenendo i gomiti stretti.
            """,
            commonMistakes: "Gomiti che si aprono, fianchi che crollano, mani troppo in avanti.",
            videoURL: "https://www.youtube.com/watch?v=J0DnG1_S92I",
            easierVariantName: "Piegamenti classici",
            equipment: ["Tappetino"],
            defaultSets: 3, defaultReps: 8, defaultRestSeconds: 60
        ),
        Exercise(
            id: "shoulder-tap",
            name: "Plank con tap alle spalle",
            category: .chestShouldersArms,
            muscles: ["Spalle", "Core", "Stabilizzatori"],
            difficulty: .beginner,
            instructions: """
            1. Posizione plank su mani, piedi leggermente più larghi dei fianchi.
            2. Tocca la spalla opposta con la mano senza ruotare il bacino.
            3. Alterna le mani mantenendo il corpo stabile.
            """,
            commonMistakes: "Bacino che oscilla, piedi troppo stretti, collo in tensione.",
            videoURL: "https://www.youtube.com/watch?v=6c2h5J7bZoY",
            equipment: ["Tappetino"],
            defaultSets: 3, defaultReps: 16, defaultRestSeconds: 45
        ),
        Exercise(
            id: "tricep-dip-chair",
            name: "Dip su sedia",
            category: .chestShouldersArms,
            muscles: ["Tricipiti", "Spalle posteriori"],
            difficulty: .beginner,
            instructions: """
            1. Seduto sul bordo di una sedia stabile, mani ai lati del corpo.
            2. Scivola avanti con i glutei fuori dalla sedia.
            3. Piega i gomiti abbassando il corpo, poi spingi su.
            """,
            commonMistakes: "Spalle che salgono verso le orecchie, gomiti che vanno troppo indietro, sedia instabile.",
            videoURL: "https://www.youtube.com/watch?v=0326dy_-CzM",
            harderVariantName: "Dip con piedi rialzati",
            equipment: ["Sedia"],
            defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
        ),

        // MARK: - Gambe/Glutei
        Exercise(
            id: "bodyweight-squat",
            name: "Squat a corpo libero",
            category: .legsGlutes,
            muscles: ["Quadricipiti", "Glutei", "Core"],
            difficulty: .beginner,
            instructions: """
            1. Piedi alla larghezza delle spalle, punte leggermente in fuori.
            2. Spingi i fianchi indietro e piega le ginocchia come per sederti.
            3. Petto alto, ginocchia in linea con le punte dei piedi.
            4. Risali spingendo sui talloni.
            """,
            commonMistakes: "Ginocchia che collassano verso l'interno, talloni che si sollevano, schiena curva.",
            videoURL: "https://www.youtube.com/watch?v=aclHkVaku9U",
            harderVariantName: "Jump squat",
            equipment: [],
            defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60
        ),
        Exercise(
            id: "reverse-lunge",
            name: "Affondo all'indietro",
            category: .legsGlutes,
            muscles: ["Quadricipiti", "Glutei", "Femorali"],
            difficulty: .beginner,
            instructions: """
            1. In piedi, fai un passo indietro con una gamba.
            2. Piega entrambe le ginocchia fino a circa 90°.
            3. Ginocchio posteriore quasi a terra, busto eretto.
            4. Spingi con il piede anteriore per tornare in piedi.
            """,
            commonMistakes: "Passo troppo corto, ginocchio anteriore oltre le dita, busto che cade in avanti.",
            videoURL: "https://www.youtube.com/watch?v=xrPteyQRegI",
            easierVariantName: "Affondo assistito (mano su sedia)",
            harderVariantName: "Affondo con salto",
            equipment: [],
            defaultSets: 3, defaultReps: 10, defaultRestSeconds: 60
        ),
        Exercise(
            id: "glute-bridge",
            name: "Glute bridge",
            category: .legsGlutes,
            muscles: ["Glutei", "Femorali", "Core"],
            difficulty: .beginner,
            instructions: """
            1. Supino, ginocchia piegate, piedi piatti a terra alla larghezza dei fianchi.
            2. Spingi sui talloni sollevando i fianchi fino a linea retta spalle-fianchi-ginocchia.
            3. Contrai i glutei in cima, poi abbassa con controllo.
            """,
            commonMistakes: "Iperestensione lombare, non contrarre i glutei, ginocchia che collassano.",
            videoURL: "https://www.youtube.com/watch?v=wPM8icPu6H8",
            harderVariantName: "Single leg glute bridge",
            equipment: ["Tappetino"],
            defaultSets: 3, defaultReps: 15, defaultRestSeconds: 45
        ),
        Exercise(
            id: "bulgarian-split-squat",
            name: "Squat bulgaro",
            category: .legsGlutes,
            muscles: ["Quadricipiti", "Glutei"],
            difficulty: .intermediate,
            instructions: """
            1. Piede posteriore appoggiato su una sedia dietro di te.
            2. Piega il ginocchio anteriore fino a circa 90°.
            3. Torso leggermente inclinato in avanti, ginocchio anteriore stabile.
            """,
            commonMistakes: "Piede posteriore troppo vicino, ginocchio che vibra, busto troppo eretto.",
            videoURL: "https://www.youtube.com/watch?v=2C-uNgKwPLE",
            easierVariantName: "Affondo all'indietro",
            equipment: ["Sedia"],
            defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
        ),
        Exercise(
            id: "wall-sit",
            name: "Seduta al muro",
            category: .legsGlutes,
            muscles: ["Quadricipiti", "Glutei"],
            difficulty: .beginner,
            instructions: """
            1. Schiena appoggiata al muro, scivola verso il basso.
            2. Ginocchia a 90°, cosce parallele al pavimento.
            3. Mantieni la posizione respirando normalmente.
            """,
            commonMistakes: "Ginocchia oltre le dita dei piedi, schiena che si stacca dal muro.",
            videoURL: "https://www.youtube.com/watch?v=y-wV4Venusw",
            equipment: [],
            defaultSets: 3, defaultReps: nil, defaultDurationSeconds: 30, defaultRestSeconds: 45, metric: .time
        ),
        Exercise(
            id: "calf-raise",
            name: "Sollevamenti polpacci",
            category: .legsGlutes,
            muscles: ["Polpacci"],
            difficulty: .beginner,
            instructions: """
            1. In piedi, piedi alla larghezza dei fianchi.
            2. Solleva i talloni il più in alto possibile.
            3. Abbassa con controllo fino a sentire lo stretch.
            """,
            commonMistakes: "Movimento troppo rapido, escursione incompleta, ginocchia che si piegano.",
            videoURL: "https://www.youtube.com/watch?v=gwLzBJYoWlI",
            harderVariantName: "Calf raise su un piede",
            equipment: [],
            defaultSets: 3, defaultReps: 20, defaultRestSeconds: 30
        ),
        Exercise(
            id: "step-up",
            name: "Step-up",
            category: .legsGlutes,
            muscles: ["Quadricipiti", "Glutei"],
            difficulty: .beginner,
            instructions: """
            1. Un piede su una sedia o gradino stabile.
            2. Spingi con il piede sulla sedia per salire completamente.
            3. Scendi con controllo e alterna le gambe.
            """,
            commonMistakes: "Spinta dal piede a terra invece che da quello sulla sedia, sedia instabile.",
            videoURL: "https://www.youtube.com/watch?v=WCFCdxzYJ_s",
            harderVariantName: "Step-up con manubri leggeri",
            equipment: ["Sedia"],
            defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
        ),

        // MARK: - Core/Addome
        Exercise(
            id: "plank",
            name: "Plank",
            category: .core,
            muscles: ["Addome", "Trasverso", "Spalle", "Glutei"],
            difficulty: .beginner,
            instructions: """
            1. Appoggio su avambracci e punte dei piedi.
            2. Corpo in linea retta, addome contratto, glutei attivi.
            3. Mantieni la posizione senza far cadere i fianchi.
            """,
            commonMistakes: "Fianchi troppo alti o troppo bassi, testa che cade, respiro bloccato.",
            videoURL: "https://www.youtube.com/watch?v=ASdvN_XEl_c",
            easierVariantName: "Plank sulle ginocchia",
            harderVariantName: "Plank con sollevamento gamba",
            equipment: ["Tappetino"],
            defaultSets: 3, defaultReps: nil, defaultDurationSeconds: 30, defaultRestSeconds: 45, metric: .time
        ),
        Exercise(
            id: "dead-bug",
            name: "Dead bug",
            category: .core,
            muscles: ["Addome profondo", "Stabilizzatori"],
            difficulty: .beginner,
            instructions: """
            1. Supino, braccia verso il soffitto, ginocchia a 90°.
            2. Abbassa braccio e gamba opposti mantenendo la schiena piatta.
            3. Torna e alterna lato.
            """,
            commonMistakes: "Schiena che si stacca dal pavimento, movimento troppo veloce.",
            videoURL: "https://www.youtube.com/watch?v=g_BYB0R-4Ws",
            equipment: ["Tappetino"],
            defaultSets: 3, defaultReps: 10, defaultRestSeconds: 45
        ),
        Exercise(
            id: "bicycle-crunch",
            name: "Crunch bicicletta",
            category: .core,
            muscles: ["Addome obliqui", "Retto addominale"],
            difficulty: .beginner,
            instructions: """
            1. Supino, mani dietro la testa senza tirare il collo.
            2. Porta gomito verso ginocchio opposto ruotando il busto.
            3. Alterna con movimento controllato.
            """,
            commonMistakes: "Tirare il collo, movimento solo delle gambe senza rotazione del busto.",
            videoURL: "https://www.youtube.com/watch?v=9FGilxFFndw",
            equipment: ["Tappetino"],
            defaultSets: 3, defaultReps: 20, defaultRestSeconds: 45
        ),
        Exercise(
            id: "mountain-climber",
            name: "Mountain climber",
            category: .core,
            muscles: ["Core", "Spalle", "Cardio"],
            difficulty: .intermediate,
            instructions: """
            1. Posizione plank alto, mani sotto le spalle.
            2. Porta un ginocchio verso il petto alternando rapidamente.
            3. Mantieni i fianchi bassi e il core attivo.
            """,
            commonMistakes: "Fianchi che salgono, piedi che toccano il pavimento con troppa forza.",
            videoURL: "https://www.youtube.com/watch?v=nmwgirgXLYM",
            easierVariantName: "Mountain climber lento",
            equipment: ["Tappetino"],
            defaultSets: 3, defaultReps: nil, defaultDurationSeconds: 30, defaultRestSeconds: 45, metric: .time
        ),
        Exercise(
            id: "hollow-hold",
            name: "Hollow hold",
            category: .core,
            muscles: ["Addome", "Flessori dell'anca"],
            difficulty: .intermediate,
            instructions: """
            1. Supino, braccia estese sopra la testa.
            2. Solleva spalle e gambe da terra, schiena premuta a terra.
            3. Corpo a forma di banana, addome contratto.
            """,
            commonMistakes: "Schiena che si stacca, ginocchia piegate, collo in tensione.",
            videoURL: "https://www.youtube.com/watch?v=44ScXWFaVBs",
            easierVariantName: "Hollow hold con ginocchia piegate",
            equipment: ["Tappetino"],
            defaultSets: 3, defaultReps: nil, defaultDurationSeconds: 20, defaultRestSeconds: 60, metric: .time
        ),
        Exercise(
            id: "side-plank",
            name: "Plank laterale",
            category: .core,
            muscles: ["Obliqui", "Gluteo medio"],
            difficulty: .beginner,
            instructions: """
            1. Appoggio su un avambraccio, corpo laterale in linea retta.
            2. Fianchi sollevati, addome contratto.
            3. Mantieni la posizione senza far cadere i fianchi.
            """,
            commonMistakes: "Fianchi che cedono, spalle che ruotano in avanti.",
            videoURL: "https://www.youtube.com/watch?v=K2VljzCC16g",
            easierVariantName: "Plank laterale sulle ginocchia",
            equipment: ["Tappetino"],
            defaultSets: 3, defaultReps: nil, defaultDurationSeconds: 25, defaultRestSeconds: 45, metric: .time
        ),

        // MARK: - Schiena
        Exercise(
            id: "superman",
            name: "Superman",
            category: .back,
            muscles: ["Erettori spinali", "Glutei", "Spalle posteriori"],
            difficulty: .beginner,
            instructions: """
            1. Prono, braccia estese in avanti.
            2. Solleva contemporaneamente petto, braccia e gambe da terra.
            3. Contrai i glutei e la schiena, poi abbassa con controllo.
            """,
            commonMistakes: "Iperestensione eccessiva del collo, movimento troppo rapido.",
            videoURL: "https://www.youtube.com/watch?v=z6PJMT2y8GQ",
            equipment: ["Tappetino"],
            defaultSets: 3, defaultReps: 12, defaultRestSeconds: 45
        ),
        Exercise(
            id: "reverse-snow-angel",
            name: "Angeli nella neve (prono)",
            category: .back,
            muscles: ["Romboidi", "Trapezio", "Spalle posteriori"],
            difficulty: .beginner,
            instructions: """
            1. Prono con fronte a terra, braccia lungo i fianchi.
            2. Solleva le braccia e le spalle da terra spingendo le scapole insieme.
            3. Abbassa con controllo.
            """,
            commonMistakes: "Sollevare la testa, movimento solo delle braccia senza retrazione scapolare.",
            videoURL: "https://www.youtube.com/watch?v=ttvfGg9d76c",
            equipment: ["Tappetino"],
            defaultSets: 3, defaultReps: 15, defaultRestSeconds: 45
        ),
        Exercise(
            id: "inverted-row-table",
            name: "Rematore invertito (tavolo)",
            category: .back,
            muscles: ["Dorsali", "Romboidi", "Bicipiti"],
            difficulty: .intermediate,
            instructions: """
            1. Sotto un tavolo robusto, afferra il bordo con presa prona.
            2. Corpo rigido, talloni a terra.
            3. Tira il petto verso il tavolo contrando la schiena.
            """,
            commonMistakes: "Fianchi che cedono, movimento solo con le braccia, tavolo instabile.",
            videoURL: "https://www.youtube.com/watch?v=hXTc1mDnZCw",
            easierVariantName: "Rematore con ginocchia piegate",
            harderVariantName: "Rematore con piedi rialzati",
            equipment: ["Tavolo robusto"],
            defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
        ),
        Exercise(
            id: "prone-y-raise",
            name: "Y raise prono",
            category: .back,
            muscles: ["Trapezio inferiore", "Spalle posteriori"],
            difficulty: .beginner,
            instructions: """
            1. Prono, braccia a Y sopra la testa.
            2. Solleva le braccia da terra spingendo i pollici verso l'alto.
            3. Contrai le scapole in cima, poi abbassa.
            """,
            commonMistakes: "Sollevare troppo in alto con il collo, movimento troppo veloce.",
            videoURL: "https://www.youtube.com/watch?v=xfDvZf5mZQA",
            equipment: ["Tappetino"],
            defaultSets: 3, defaultReps: 12, defaultRestSeconds: 45
        ),
        Exercise(
            id: "good-morning-bodyweight",
            name: "Good morning a corpo libero",
            category: .back,
            muscles: ["Femorali", "Erettori spinali", "Glutei"],
            difficulty: .intermediate,
            instructions: """
            1. In piedi, mani dietro la testa o incrociate sul petto.
            2. Piega i fianchi indietro mantenendo la schiena neutra.
            3. Senti lo stretch sui femorali, poi torna eretto contrando i glutei.
            """,
            commonMistakes: "Schiena arrotondata, piegarsi troppo in basso, ginocchia che si bloccano.",
            videoURL: "https://www.youtube.com/watch?v=nYJ1AkxZVwE",
            equipment: [],
            defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
        ),

        // MARK: - Cardio/HIIT
        Exercise(
            id: "jumping-jack",
            name: "Jumping jack",
            category: .cardioHIIT,
            muscles: ["Cardio", "Gambe", "Spalle"],
            difficulty: .beginner,
            instructions: """
            1. In piedi, piedi uniti, braccia lungo i fianchi.
            2. Salta aprendo gambe e braccia simultaneamente.
            3. Torna alla posizione iniziale con un altro salto.
            """,
            commonMistakes: "Atterraggio rigido sulle ginocchia, braccia che non arrivano sopra la testa.",
            videoURL: "https://www.youtube.com/watch?v=UpH7rm0cYbM",
            equipment: [],
            defaultSets: 3, defaultReps: nil, defaultDurationSeconds: 30, defaultRestSeconds: 30, metric: .time
        ),
        Exercise(
            id: "high-knees",
            name: "Ginocchia alte",
            category: .cardioHIIT,
            muscles: ["Cardio", "Core", "Flessori dell'anca"],
            difficulty: .beginner,
            instructions: """
            1. Corsa sul posto portando le ginocchia all'altezza dei fianchi.
            2. Braccia che oscillano naturalmente.
            3. Mantieni il ritmo e il core attivo.
            """,
            commonMistakes: "Inclinarsi troppo indietro, ginocchia basse, respiro irregolare.",
            videoURL: "https://www.youtube.com/watch?v=oDdkytliOqE",
            equipment: [],
            defaultSets: 3, defaultReps: nil, defaultDurationSeconds: 30, defaultRestSeconds: 30, metric: .time
        ),
        Exercise(
            id: "burpee",
            name: "Burpee",
            category: .cardioHIIT,
            muscles: ["Corpo intero", "Cardio"],
            difficulty: .advanced,
            instructions: """
            1. Dalla posizione in piedi, scendi in squat e metti le mani a terra.
            2. Salta indietro in plank, poi avanti di nuovo.
            3. Salta in alto con le braccia sopra la testa.
            """,
            commonMistakes: "Schiena curva nel plank, atterraggio duro, saltare senza controllo.",
            videoURL: "https://www.youtube.com/watch?v=auBLPXO8Fww",
            easierVariantName: "Burpee senza salto",
            equipment: ["Tappetino"],
            defaultSets: 3, defaultReps: 8, defaultRestSeconds: 60
        ),
        Exercise(
            id: "skater-hop",
            name: "Skater hop",
            category: .cardioHIIT,
            muscles: ["Gambe", "Glutei", "Cardio"],
            difficulty: .intermediate,
            instructions: """
            1. Salta lateralmente da una gamba all'altra.
            2. Gamba libera che va dietro in un leggero affondo.
            3. Braccia che bilanciano il movimento.
            """,
            commonMistakes: "Ginocchio che collassa verso l'interno, atterraggio senza ammortizzazione.",
            videoURL: "https://www.youtube.com/watch?v=9_jLW6VkJ8E",
            equipment: [],
            defaultSets: 3, defaultReps: nil, defaultDurationSeconds: 30, defaultRestSeconds: 45, metric: .time
        ),
        Exercise(
            id: "jump-squat",
            name: "Jump squat",
            category: .cardioHIIT,
            muscles: ["Quadricipiti", "Glutei", "Cardio"],
            difficulty: .intermediate,
            instructions: """
            1. Esegui uno squat completo.
            2. Esplodi verso l'alto con un salto.
            3. Atterra morbido tornando subito in squat.
            """,
            commonMistakes: "Atterraggio rigido, ginocchia che collassano, squat incompleto.",
            videoURL: "https://www.youtube.com/watch?v=CVaEhXotL7M",
            easierVariantName: "Squat a corpo libero",
            equipment: [],
            defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
        ),

        // MARK: - Mobilità/Stretching
        Exercise(
            id: "cat-cow",
            name: "Gatto-mucca",
            category: .mobility,
            muscles: ["Colonna vertebrale", "Core"],
            difficulty: .beginner,
            instructions: """
            1. A quattro zampe, mani sotto le spalle, ginocchia sotto i fianchi.
            2. Inspira: inarca la schiena (mucca), guarda in alto.
            3. Espira: arrotonda la schiena (gatto), mento al petto.
            """,
            commonMistakes: "Movimento solo del collo, andare troppo veloce.",
            videoURL: "https://www.youtube.com/watch?v=kqnua4rHVVA",
            equipment: ["Tappetino"],
            defaultSets: 2, defaultReps: 10, defaultRestSeconds: 15
        ),
        Exercise(
            id: "hip-flexor-stretch",
            name: "Stretch flessori dell'anca",
            category: .mobility,
            muscles: ["Flessori dell'anca", "Quadricipiti"],
            difficulty: .beginner,
            instructions: """
            1. Affondo in ginocchio, piede anteriore piatto.
            2. Spingi i fianchi in avanti mantenendo il busto eretto.
            3. Senti lo stretch nella parte anteriore dell'anca posteriore.
            """,
            commonMistakes: "Inclinarsi in avanti perdendo lo stretch, ginocchio che va oltre le dita.",
            videoURL: "https://www.youtube.com/watch?v=zgS8ExpKwa8",
            equipment: ["Tappetino"],
            defaultSets: 2, defaultReps: nil, defaultDurationSeconds: 30, defaultRestSeconds: 10, metric: .time
        ),
        Exercise(
            id: "child-pose",
            name: "Posizione del bambino",
            category: .mobility,
            muscles: ["Schiena", "Fianchi", "Spalle"],
            difficulty: .beginner,
            instructions: """
            1. In ginocchio, sediti sui talloni e piegati in avanti.
            2. Braccia estese in avanti, fronte a terra.
            3. Respira profondamente rilassando la schiena.
            """,
            commonMistakes: "Tensione nelle spalle, non rilassare il collo.",
            videoURL: "https://www.youtube.com/watch?v=2MTd6Q9PKHk",
            equipment: ["Tappetino"],
            defaultSets: 1, defaultReps: nil, defaultDurationSeconds: 60, defaultRestSeconds: 0, metric: .time
        ),
        Exercise(
            id: "worlds-greatest-stretch",
            name: "World's greatest stretch",
            category: .mobility,
            muscles: ["Fianchi", "Toracica", "Femorali"],
            difficulty: .intermediate,
            instructions: """
            1. Affondo profondo con mano opposta a terra.
            2. Ruota il busto aprendo il braccio verso il soffitto.
            3. Torna e ripeti dall'altro lato.
            """,
            commonMistakes: "Affondo troppo corto, perdere l'equilibrio, movimento brusco.",
            videoURL: "https://www.youtube.com/watch?v=3E8jKxQvKqQ",
            equipment: ["Tappetino"],
            defaultSets: 2, defaultReps: 6, defaultRestSeconds: 15
        ),
        Exercise(
            id: "hamstring-stretch",
            name: "Stretch femorali",
            category: .mobility,
            muscles: ["Femorali", "Polpacci"],
            difficulty: .beginner,
            instructions: """
            1. Seduto, una gamba estesa, l'altra piegata.
            2. Piega il busto in avanti dalla vita mantenendo la schiena piatta.
            3. Tieni la posizione senza forzare.
            """,
            commonMistakes: "Arrotondare la schiena, tirare troppo aggressivamente.",
            videoURL: "https://www.youtube.com/watch?v=7c1c7Gd8sdE",
            equipment: ["Tappetino"],
            defaultSets: 2, defaultReps: nil, defaultDurationSeconds: 30, defaultRestSeconds: 10, metric: .time
        ),
        Exercise(
            id: "thoracic-rotation",
            name: "Rotazione toracica",
            category: .mobility,
            muscles: ["Toracica", "Core"],
            difficulty: .beginner,
            instructions: """
            1. A quattro zampe, una mano dietro la testa.
            2. Ruota il gomito verso il soffitto aprendo il petto.
            3. Torna e ripeti, poi cambia lato.
            """,
            commonMistakes: "Ruotare solo il collo, muovere troppo i fianchi.",
            videoURL: "https://www.youtube.com/watch?v=6BSi4X0eq4A",
            equipment: ["Tappetino"],
            defaultSets: 2, defaultReps: 8, defaultRestSeconds: 15
        ),
    ]

    static func exercise(byID id: String) -> Exercise? {
        allExercises.first { $0.id == id }
    }
}
