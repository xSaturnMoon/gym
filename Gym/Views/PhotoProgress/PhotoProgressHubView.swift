import SwiftUI
import SwiftData

struct PhotoProgressHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProgressPhoto.capturedAt, order: .reverse) private var photos: [ProgressPhoto]
    @Query private var settingsList: [ProgressPhotoSettings]

    @State private var service: ProgressPhotoService?
    @State private var showCapture = false
    @State private var showSettings = false
    @State private var selectedPhoto: ProgressPhoto?
    @State private var compareWithBaseline = true
    @State private var showDeleteAllAlert = false

    private var settings: ProgressPhotoSettings? { settingsList.first }
    private var baseline: ProgressPhoto? { photos.first { $0.isBaseline } }

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 20) {
                VStack(spacing: 20) {
                    headerSection
                    captureButton
                    PhotoTimelineView(photos: photos, selectedPhoto: $selectedPhoto)

                    if let selected = selectedPhoto {
                        selectedPhotoSection(selected)
                    }

                    if photos.count >= 2 {
                        comparisonSection
                    }

                    if photos.count >= 1 {
                        MetricsChartView(photos: photos)
                    }

                    privacySection
                }
                .padding()
            }
        }
        .background(
            LinearGradient(
                colors: [Color.black, Color(red: 0.06, green: 0.04, blue: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Foto Progressi")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .fullScreenCover(isPresented: $showCapture) {
            PhotoCaptureScreen()
        }
        .sheet(isPresented: $showSettings) {
            PhotoProgressSettingsView()
        }
        .alert("Elimina tutte le foto?", isPresented: $showDeleteAllAlert) {
            Button("Annulla", role: .cancel) {}
            Button("Elimina tutto", role: .destructive) {
                service?.deleteAllPhotos()
                selectedPhoto = nil
                HapticService.warning()
            }
        } message: {
            Text("Tutte le foto e le analisi verranno eliminate dal dispositivo. Questa azione non può essere annullata.")
        }
        .onAppear {
            service = ProgressPhotoService(modelContext: modelContext)
            if selectedPhoto == nil { selectedPhoto = photos.first }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                title: "Progressi fisici",
                subtitle: baseline == nil
                    ? "Scatta la prima foto di riferimento per iniziare il monitoraggio."
                    : "Confronto standardizzato con la tua foto baseline."
            )

            if let hour = settings?.suggestedCaptureHour {
                Label("Momento consigliato: ore \(hour):00", systemImage: "sun.max.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var captureButton: some View {
        Button {
            showCapture = true
        } label: {
            Label(
                baseline == nil ? "Scatta foto di riferimento" : "Scatta foto di oggi",
                systemImage: "camera.fill"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
    }

    @ViewBuilder
    private func selectedPhotoSection(_ photo: ProgressPhoto) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(photo.capturedAt, style: .date)
                    .font(.headline)
                Spacer()
                if photo.isBaseline {
                    Text("Baseline")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .glassEffect(.regular.tint(.blue.opacity(0.2)), in: .capsule)
                }
                Button(role: .destructive) {
                    service?.deletePhoto(photo)
                    selectedPhoto = photos.first { $0.id != photo.id }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.glass)
            }

            if let uiImage = UIImage(data: photo.displayImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            HStack(spacing: 12) {
                MetricChip(icon: "scope", text: "Allineamento \(Int(photo.alignmentScore * 100))%")
                MetricChip(icon: "arrow.triangle.merge", text: "Confronto \(Int(photo.comparabilityScore * 100))%")
                MetricChip(icon: "camera", text: photo.cameraFacing.rawValue)
            }

            if let report = photo.analysisReport {
                PhotoAnalysisReportView(report: report, metrics: photo.metrics)
            }

            if !photo.isBaseline, let baselineMetrics = baseline?.metrics, let currentMetrics = photo.metrics {
                let changes = ProgressMetricsService.metricChanges(current: currentMetrics, baseline: baselineMetrics)
                if !changes.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("vs Baseline", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.headline)
                            ForEach(changes, id: \.self) { change in
                                Text("• \(change)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var comparisonSection: some View {
        if let selected = selectedPhoto {
            let other = compareWithBaseline ? baseline : photos.first { $0.id != selected.id && $0.capturedAt < selected.capturedAt }
            if let other, other.id != selected.id {
                PhotoComparisonView(photoA: other, photoB: selected)

                Toggle("Confronta con baseline", isOn: $compareWithBaseline)
                    .font(.caption)
                    .tint(.accentColor)
            }
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Privacy", systemImage: "lock.shield.fill")
                .font(.headline)

            Text("Le foto sono salvate solo sul tuo dispositivo. L'analisi AI invia la foto a Gemini solo al momento dell'analisi, se abilitata.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Elimina tutte le foto", role: .destructive) {
                showDeleteAllAlert = true
            }
            .font(.caption)
            .buttonStyle(.glass)
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}

struct PhotoProgressSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [ProgressPhotoSettings]

    @State private var apiKey = ""
    @State private var aiEnabled = true
    @State private var camera: CameraFacing = .front
    @State private var captureHour = 8

    var body: some View {
        NavigationStack {
            Form {
                Section("Camera") {
                    Picker("Fotocamera", selection: $camera) {
                        ForEach(CameraFacing.allCases) { facing in
                            Text(facing.rawValue).tag(facing)
                        }
                    }
                    Stepper("Ora consigliata: \(captureHour):00", value: $captureHour, in: 5...12)
                }

                Section {
                    Toggle("Analisi AI (Gemini)", isOn: $aiEnabled)
                    SecureField("Google Gemini API Key", text: $apiKey)
                        .textContentType(.password)
                } header: {
                    Text("Analisi AI")
                } footer: {
                    Text("La chiave API è salvata nel Keychain del dispositivo. Ottienila gratuitamente su aistudio.google.com/apikey")
                }
            }
            .navigationTitle("Impostazioni foto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { save(); dismiss() }
                }
            }
            .onAppear { load() }
        }
        .presentationDetents([.medium, .large])
    }

    private func load() {
        let settings = settingsList.first ?? ProgressPhotoSettings()
        apiKey = KeychainHelper.loadGeminiAPIKey() ?? ""
        aiEnabled = settings.aiAnalysisEnabled
        camera = settings.preferredCamera
        captureHour = settings.suggestedCaptureHour
    }

    private func save() {
        let settings = settingsList.first ?? {
            let s = ProgressPhotoSettings()
            modelContext.insert(s)
            return s
        }()
        KeychainHelper.saveGeminiAPIKey(apiKey)
        settings.aiAnalysisEnabled = aiEnabled
        settings.preferredCamera = camera
        settings.suggestedCaptureHour = captureHour
        try? modelContext.save()
    }
}
