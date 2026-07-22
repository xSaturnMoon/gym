import Foundation

@MainActor
enum ClaudeAnalysisService {
    static let systemPrompt = """
    Sei un assistente di analisi progressi fisici per un'app di allenamento a casa.
    Ricevi foto NORMALIZZATE (allineate per posa/distanza) e metriche geometriche derivate dai landmark corporei.

    REGOLE OBBLIGATORIE:
    1. Basa le conclusioni SOLO su differenze osservabili tra foto normalizzate e sulle metriche fornite.
    2. Se l'affidabilità del confronto è bassa o la normalizzazione è incerta, dichiaralo esplicitamente e NON inventare cambiamenti.
    3. Evita giudizi estetici generici ("sei in forma", "bel fisico"). Usa descrizioni concrete e localizzate.
    4. Collega i suggerimenti al piano di allenamento indicato, se presente.
    5. Non fare diagnosi mediche. Non commentare peso corporeo se non fornito.
    6. Rispondi SOLO con JSON valido, senza markdown, nel formato:
    {
      "reliability": "high" | "medium" | "low",
      "summary": "stringa breve",
      "observedChanges": ["..."],
      "localizedChanges": ["cambiamento in zona X..."],
      "suggestions": ["suggerimento pratico..."],
      "comparabilityNote": "nota sulla qualità del confronto"
    }
      "reliability" deve riflettere quanto le foto sono comparabili (posa, allineamento, luce).
    """

    static func analyze(
        normalizedImageData: Data,
        metrics: BodyMetrics,
        baselineMetrics: BodyMetrics?,
        previousMetrics: BodyMetrics?,
        comparabilityScore: Double,
        alignmentScore: Double,
        activePlanName: String?,
        apiKey: String
    ) async throws -> AIAnalysisResult {
        let base64 = normalizedImageData.base64EncodedString()
        let mediaType = "image/jpeg"

        var userText = """
        Analizza questa foto di progresso normalizzata.

        Metriche attuali:
        - Rapporto spalle/fianchi: \(String(format: "%.3f", metrics.shoulderToHipRatio))
        - Allineamento spalle: \(String(format: "%.1f", metrics.shoulderAlignmentDegrees))°
        - Allineamento bacino: \(String(format: "%.1f", metrics.hipAlignmentDegrees))°
        - Definizione addome: \(String(format: "%.2f", metrics.abdomenDefinition))
        - Definizione braccia: \(String(format: "%.2f", metrics.armsDefinition))
        - Definizione gambe: \(String(format: "%.2f", metrics.legsDefinition))
        - Postura: \(String(format: "%.2f", metrics.postureScore))

        Affidabilità allineamento: \(String(format: "%.0f", alignmentScore * 100))%
        Affidabilità comparabilità: \(String(format: "%.0f", comparabilityScore * 100))%
        """

        if let baseline = baselineMetrics {
            let delta = metrics.delta(from: baseline)
            userText += """

            Delta rispetto alla baseline:
            - Addome: \(String(format: "%+.3f", delta["abdomenDefinition"] ?? 0))
            - Braccia: \(String(format: "%+.3f", delta["armsDefinition"] ?? 0))
            - Gambe: \(String(format: "%+.3f", delta["legsDefinition"] ?? 0))
            - Postura: \(String(format: "%+.3f", delta["postureScore"] ?? 0))
            """
        }

        if let previous = previousMetrics {
            let delta = metrics.delta(from: previous)
            userText += """

            Delta rispetto alla foto precedente:
            - Addome: \(String(format: "%+.3f", delta["abdomenDefinition"] ?? 0))
            - Postura: \(String(format: "%+.3f", delta["postureScore"] ?? 0))
            """
        }

        if let plan = activePlanName {
            userText += "\n\nPiano attivo: \(plan)"
        }

        if comparabilityScore < PoseGuideTemplate.minimumComparabilityScore {
            userText += "\n\nATTENZIONE: comparabilità sotto soglia. Imposta reliability a \"low\"."
        }

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": mediaType,
                                "data": base64
                            ]
                        ],
                        [
                            "type": "text",
                            "text": userText
                        ]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Errore API"
            throw ClaudeError.apiError(message)
        }

        return try parseResponse(data)
    }

    static func localFallbackAnalysis(
        metrics: BodyMetrics,
        baseline: BodyMetrics?,
        comparabilityScore: Double,
        geometricChanges: [String]
    ) -> AIAnalysisResult {
        let reliability: AnalysisReliability = if comparabilityScore >= 0.8 {
            .high
        } else if comparabilityScore >= PoseGuideTemplate.minimumComparabilityScore {
            .medium
        } else {
            .low
        }

        var changes = geometricChanges
        if changes.isEmpty && baseline != nil {
            changes.append("Nessun cambiamento significativo rilevato nelle metriche geometriche.")
        } else if baseline == nil {
            changes = ProgressMetricsService.descriptiveBaselineReport(metrics: metrics)
        }

        return AIAnalysisResult(
            reliability: reliability,
            summary: baseline == nil
                ? "Foto di riferimento registrata. Le prossime foto verranno confrontate con questa baseline."
                : "Analisi basata su metriche geometriche locali (API non configurata o disabilitata).",
            observedChanges: changes,
            localizedChanges: changes,
            suggestions: [
                "Scatta sempre alla stessa ora, con la stessa camera e sfondo neutro.",
                "Allineati alla sagoma guida prima di ogni scatto.",
                "Continua con costanza il piano di allenamento attivo."
            ],
            comparabilityNote: reliability == .low
                ? "Confronto a bassa affidabilità: ripeti lo scatto allineandoti meglio alla guida."
                : "Confronto basato su normalizzazione landmark."
        )
    }

    private static func parseResponse(_ data: Data) throws -> AIAnalysisResult {
        struct APIResponse: Decodable {
            struct Content: Decodable { let text: String }
            let content: [Content]
        }

        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        guard let text = apiResponse.content.first?.text else {
            throw ClaudeError.invalidResponse
        }

        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw ClaudeError.invalidResponse
        }

        struct RawResult: Decodable {
            let reliability: String
            let summary: String
            let observedChanges: [String]
            let localizedChanges: [String]
            let suggestions: [String]
            let comparabilityNote: String
        }

        let raw = try JSONDecoder().decode(RawResult.self, from: jsonData)
        let reliability = AnalysisReliability(rawValue: mapReliability(raw.reliability)) ?? .medium

        return AIAnalysisResult(
            reliability: reliability,
            summary: raw.summary,
            observedChanges: raw.observedChanges,
            localizedChanges: raw.localizedChanges,
            suggestions: raw.suggestions,
            comparabilityNote: raw.comparabilityNote
        )
    }

    private static func mapReliability(_ value: String) -> String {
        switch value.lowercased() {
        case "high", "alta": AnalysisReliability.high.rawValue
        case "low", "bassa": AnalysisReliability.low.rawValue
        default: AnalysisReliability.medium.rawValue
        }
    }

    enum ClaudeError: LocalizedError {
        case apiError(String)
        case invalidResponse
        case missingAPIKey

        var errorDescription: String? {
            switch self {
            case .apiError(let msg): "Errore API Claude: \(msg)"
            case .invalidResponse: "Risposta API non valida."
            case .missingAPIKey: "Chiave API Claude non configurata."
            }
        }
    }
}
