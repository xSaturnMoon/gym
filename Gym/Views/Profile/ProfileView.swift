import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var engine: WorkoutEngine?
    @State private var showResetAlert = false
    @State private var name = ""
    @State private var weightText = ""
    @State private var selectedGoal: WorkoutGoal = .energy
    @State private var weightUnit: WeightUnit = .kg
    @State private var lengthUnit: LengthUnit = .cm
    @State private var remindersEnabled = false
    @State private var reminderTime = Date()

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Form {
                personalSection
                goalsSection
                unitsSection
                notificationsSection
                aboutSection
                dangerSection
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Profilo")
            .onAppear {
                engine = WorkoutEngine(modelContext: modelContext)
                loadProfile()
            }
            .onChange(of: name) { _, _ in saveProfile() }
            .onChange(of: weightText) { _, _ in saveProfile() }
            .onChange(of: selectedGoal) { _, _ in saveProfile() }
            .onChange(of: weightUnit) { _, _ in saveProfile() }
            .onChange(of: lengthUnit) { _, _ in saveProfile() }
            .alert("Reset dati", isPresented: $showResetAlert) {
                Button("Annulla", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    engine?.resetAllData()
                    loadProfile()
                    HapticService.warning()
                }
            } message: {
                Text("Tutti i dati verranno eliminati e reimpostati ai valori iniziali. Questa azione non può essere annullata.")
            }
        }
    }

    private var personalSection: some View {
        Section {
            TextField("Nome", text: $name)
            HStack {
                TextField("Peso (opzionale)", text: $weightText)
                    .keyboardType(.decimalPad)
                Text(weightUnit.rawValue)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Dati personali")
        }
    }

    private var goalsSection: some View {
        Section {
            Picker("Obiettivo", selection: $selectedGoal) {
                ForEach(WorkoutGoal.allCases) { goal in
                    Label(goal.rawValue, systemImage: goal.icon).tag(goal)
                }
            }
        } header: {
            Text("Obiettivo")
        } footer: {
            Text("L'obiettivo influenza i suggerimenti e la progressione del piano.")
        }
    }

    private var unitsSection: some View {
        Section("Unità di misura") {
            Picker("Peso", selection: $weightUnit) {
                ForEach(WeightUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            Picker("Altezza", selection: $lengthUnit) {
                ForEach(LengthUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle("Promemoria allenamento", isOn: $remindersEnabled)
                .onChange(of: remindersEnabled) { _, enabled in
                    Task {
                        if enabled {
                            let granted = await NotificationService.requestPermission()
                            if granted {
                                scheduleReminder()
                            } else {
                                remindersEnabled = false
                            }
                        } else {
                            NotificationService.cancelReminders()
                        }
                        saveProfile()
                    }
                }

            if remindersEnabled {
                DatePicker("Orario", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .onChange(of: reminderTime) { _, _ in
                        scheduleReminder()
                        saveProfile()
                    }
            }
        } header: {
            Text("Notifiche")
        } footer: {
            Text("Ricevi un promemoria giornaliero per non saltare l'allenamento.")
        }
    }

    private var aboutSection: some View {
        Section("Info app") {
            LabeledContent("Versione", value: "1.0.0")
            LabeledContent("Piattaforma", value: "iOS 26")
            LabeledContent("Bundle ID", value: "com.xsaturnmoon.gym")
        }
    }

    private var dangerSection: some View {
        Section {
            Button("Reset tutti i dati", role: .destructive) {
                showResetAlert = true
            }
        }
    }

    private func loadProfile() {
        guard let profile else { return }
        name = profile.name
        if let weight = profile.weight {
            weightText = String(format: "%.1f", weight)
        }
        selectedGoal = profile.goal
        weightUnit = profile.weightUnit
        lengthUnit = profile.lengthUnit
        remindersEnabled = profile.remindersEnabled
        var components = DateComponents()
        components.hour = profile.reminderHour
        components.minute = profile.reminderMinute
        reminderTime = Calendar.current.date(from: components) ?? Date()
    }

    private func saveProfile() {
        let profile = profiles.first ?? {
            let p = UserProfile()
            modelContext.insert(p)
            return p
        }()

        profile.name = name
        profile.weight = Double(weightText.replacingOccurrences(of: ",", with: "."))
        profile.goal = selectedGoal
        profile.weightUnit = weightUnit
        profile.lengthUnit = lengthUnit
        profile.remindersEnabled = remindersEnabled
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        profile.reminderHour = components.hour ?? 8
        profile.reminderMinute = components.minute ?? 0
        try? modelContext.save()
    }

    private func scheduleReminder() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        NotificationService.scheduleDailyReminder(
            hour: components.hour ?? 8,
            minute: components.minute ?? 0
        )
    }
}
