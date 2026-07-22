import SwiftUI
import Charts

struct PhotoAnalysisReportView: View {
    let report: ProgressAnalysisReport
    let metrics: BodyMetrics?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Analisi", systemImage: "sparkles")
                    .font(.headline)
                Spacer()
                reliabilityBadge
            }

            if report.wasSentToAPI {
                Label("Foto inviata per analisi AI", systemImage: "icloud.and.arrow.up")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Label("Analisi locale (nessun invio)", systemImage: "iphone")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(report.summaryText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !report.localizedChanges.isEmpty {
                section(title: "Cambiamenti osservati", icon: "arrow.triangle.2.circlepath", items: report.localizedChanges)
            }

            if !report.suggestions.isEmpty {
                section(title: "Suggerimenti", icon: "lightbulb.fill", items: report.suggestions)
            }

            if !report.comparabilityNote.isEmpty {
                Text(report.comparabilityNote)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .italic()
            }

            if let metrics {
                metricsGrid(metrics)
            }
        }
        .padding()
        .glassEffect(.regular.tint(.accentColor.opacity(0.08)), in: .rect(cornerRadius: 20))
    }

    private var reliabilityBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: report.reliability.icon)
            Text("Affidabilità \(report.reliability.rawValue)")
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .glassEffect(.regular, in: .capsule)
    }

    private func section(title: String, icon: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                    Text(item).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func metricsGrid(_ metrics: BodyMetrics) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Metriche")
                .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                metricCell("Spalle/fianchi", String(format: "%.2f", metrics.shoulderToHipRatio))
                metricCell("Postura", String(format: "%.0f%%", metrics.postureScore * 100))
                metricCell("Addome", definitionShort(metrics.abdomenDefinition))
                metricCell("Braccia", definitionShort(metrics.armsDefinition))
                metricCell("Gambe", definitionShort(metrics.legsDefinition))
                metricCell("Allin. spalle", String(format: "%.1f°", metrics.shoulderAlignmentDegrees))
            }
        }
    }

    private func metricCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.caption.weight(.bold))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .glassEffect(.regular, in: .rect(cornerRadius: 10))
    }

    private func definitionShort(_ value: Double) -> String {
        switch value {
        case 0.7...: "Marcata"
        case 0.55..<0.7: "Visibile"
        case 0.4..<0.55: "Moderata"
        default: "Leggera"
        }
    }
}

struct PhotoTimelineView: View {
    let photos: [ProgressPhoto]
    @Binding var selectedPhoto: ProgressPhoto?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)

            if photos.isEmpty {
                Text("Nessuna foto ancora. Scatta la tua prima foto di riferimento.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(photos) { photo in
                            timelineCard(photo)
                        }
                    }
                }
            }
        }
    }

    private func timelineCard(_ photo: ProgressPhoto) -> some View {
        Button {
            selectedPhoto = photo
        } label: {
            VStack(spacing: 6) {
                if let uiImage = UIImage(data: photo.displayImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            if photo.isBaseline {
                                Text("BASE")
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .glassEffect(.regular.tint(.blue.opacity(0.3)), in: .capsule)
                                    .frame(maxHeight: .infinity, alignment: .top)
                                    .padding(4)
                            }
                        }
                }

                Text(photo.capturedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("\(Int(photo.comparabilityScore * 100))%")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(photo.comparabilityScore >= PoseGuideTemplate.minimumComparabilityScore ? .green : .orange)
            }
            .padding(8)
            .glassEffect(
                selectedPhoto?.id == photo.id
                    ? .regular.tint(.accentColor.opacity(0.2)).interactive()
                    : .regular.interactive(),
                in: .rect(cornerRadius: 16)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PhotoComparisonView: View {
    let photoA: ProgressPhoto
    let photoB: ProgressPhoto
    @State private var overlayOpacity: Double = 0.5

    var body: some View {
        VStack(spacing: 16) {
            Text("Confronto")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                if let imageA = UIImage(data: photoA.displayImageData) {
                    Image(uiImage: imageA)
                        .resizable()
                        .scaledToFit()
                }
                if let imageB = UIImage(data: photoB.displayImageData) {
                    Image(uiImage: imageB)
                        .resizable()
                        .scaledToFit()
                        .opacity(overlayOpacity)
                }
            }
            .frame(maxHeight: 400)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .glassEffect(.regular, in: .rect(cornerRadius: 16))

            VStack(spacing: 8) {
                HStack {
                    Text(photoA.capturedAt, style: .date)
                        .font(.caption)
                    Spacer()
                    Text("Overlay")
                        .font(.caption)
                    Spacer()
                    Text(photoB.capturedAt, style: .date)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                Slider(value: $overlayOpacity, in: 0...1)
                    .tint(.accentColor)
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
    }
}

struct MetricsChartView: View {
    let photos: [ProgressPhoto]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metriche nel tempo")
                .font(.headline)

            let sorted = photos.sorted { $0.capturedAt < $1.capturedAt }
            let chartData = sorted.compactMap { photo -> (Date, Double)? in
                guard let metrics = photo.metrics else { return nil }
                return (photo.capturedAt, metrics.postureScore)
            }

            if chartData.count < 2 {
                Text("Servono almeno 2 foto per il grafico.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(chartData, id: \.0) { item in
                    LineMark(
                        x: .value("Data", item.0),
                        y: .value("Postura", item.1)
                    )
                    .foregroundStyle(Color.accentColor)
                    PointMark(
                        x: .value("Data", item.0),
                        y: .value("Postura", item.1)
                    )
                }
                .frame(height: 140)
            }
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}
