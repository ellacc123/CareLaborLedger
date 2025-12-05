import SwiftUI

// MARK: - Models
struct CareEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let taskType: CareTaskType
    let recipientType: RecipientType
    let emotionalWeight: Int // 1-5 scale
    let timeSpent: Int // minutes
    let notes: String
    let wasVisible: Bool
    
    init(id: UUID = UUID(), timestamp: Date = Date(), taskType: CareTaskType, recipientType: RecipientType, emotionalWeight: Int, timeSpent: Int, notes: String, wasVisible: Bool) {
        self.id = id
        self.timestamp = timestamp
        self.taskType = taskType
        self.recipientType = recipientType
        self.emotionalWeight = emotionalWeight
        self.timeSpent = timeSpent
        self.notes = notes
        self.wasVisible = wasVisible
    }
}

enum CareTaskType: String, CaseIterable, Codable {
    case emotionalSupport = "Emotional Support"
    case groupWork = "Group Project Labor"
    case mentoring = "Peer Mentoring"
    case spaceKeeping = "Space Tending"
    case conflictMediation = "Conflict Mediation"
    case administration = "Admin/Organizing"
    case translation = "Cultural Translation"
    case listening = "Active Listening"
    
    var icon: String {
        switch self {
        case .emotionalSupport: return "heart.fill"
        case .groupWork: return "person.3.fill"
        case .mentoring: return "book.fill"
        case .spaceKeeping: return "house.fill"
        case .conflictMediation: return "bubble.left.and.bubble.right.fill"
        case .administration: return "calendar"
        case .translation: return "globe"
        case .listening: return "ear.fill"
        }
    }
}

enum RecipientType: String, CaseIterable, Codable {
    case peer = "Peer/Friend"
    case roommate = "Roommate"
    case groupProject = "Group Project"
    case family = "Family"
    case community = "Community/Campus"
    case self_care = "Self"
}

// MARK: - Data Manager
class CareDataManager: ObservableObject {
    @Published var entries: [CareEntry] = []
    
    private let saveKey = "CareEntries"
    
    init() {
        loadEntries()
    }
    
    func addEntry(_ entry: CareEntry) {
        entries.insert(entry, at: 0)
        saveEntries()
    }
    
    func deleteEntry(_ entry: CareEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([CareEntry].self, from: data) {
            entries = decoded
        }
    }
    
    var totalHours: Double {
        Double(entries.reduce(0) { $0 + $1.timeSpent }) / 60.0
    }
    
    var invisibleHours: Double {
        Double(entries.filter { !$0.wasVisible }.reduce(0) { $0 + $1.timeSpent }) / 60.0
    }
    
    var totalEmotionalWeight: Int {
        entries.reduce(0) { $0 + $1.emotionalWeight }
    }
}

// MARK: - Main App
@main
struct CareLaborLedgerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Content View
struct ContentView: View {
    @StateObject private var dataManager = CareDataManager()
    @State private var showingAddEntry = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LedgerView(dataManager: dataManager, showingAddEntry: $showingAddEntry)
                .tabItem {
                    Label("Ledger", systemImage: "book.fill")
                }
                .tag(0)
            
            InsightsView(dataManager: dataManager)
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            InstructionsView()
                .tabItem {
                    Label("Instructions", systemImage: "questionmark.circle.fill")
                }
                .tag(2)
        }
        .sheet(isPresented: $showingAddEntry) {
            AddEntryView(dataManager: dataManager, isPresented: $showingAddEntry)
        }
    }
}

// MARK: - Ledger View
struct LedgerView: View {
    @ObservedObject var dataManager: CareDataManager
    @Binding var showingAddEntry: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                if dataManager.entries.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No care labor logged yet")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text("Tap + to make invisible labor visible")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(dataManager.entries) { entry in
                            EntryRow(entry: entry)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                dataManager.deleteEntry(dataManager.entries[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Care Labor Ledger")
            .toolbar {
                Button(action: { showingAddEntry = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
    }
}

// MARK: - Entry Row
struct EntryRow: View {
    let entry: CareEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.taskType.icon)
                    .foregroundColor(.blue)
                Text(entry.taskType.rawValue)
                    .font(.headline)
                Spacer()
                if !entry.wasVisible {
                    Image(systemName: "eye.slash.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            HStack {
                Text(entry.recipientType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(entry.timeSpent) min")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("Emotional weight:")
                    .font(.caption)
                    .foregroundColor(.gray)
                ForEach(0..<entry.emotionalWeight, id: \.self) { _ in
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Entry View
struct AddEntryView: View {
    @ObservedObject var dataManager: CareDataManager
    @Binding var isPresented: Bool
    
    @State private var selectedTaskType: CareTaskType = .emotionalSupport
    @State private var selectedRecipient: RecipientType = .peer
    @State private var emotionalWeight: Int = 3
    @State private var timeSpent: Int = 30
    @State private var notes: String = ""
    @State private var wasVisible: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("What care work did you do?")) {
                    Picker("Type of Care", selection: $selectedTaskType) {
                        ForEach(CareTaskType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                        }
                    }
                    
                    Picker("For whom?", selection: $selectedRecipient) {
                        ForEach(RecipientType.allCases, id: \.self) { recipient in
                            Text(recipient.rawValue)
                        }
                    }
                }
                
                Section(header: Text("Emotional Weight (1-5)")) {
                    HStack {
                        Text("Light")
                            .font(.caption)
                        Slider(value: Binding(
                            get: { Double(emotionalWeight) },
                            set: { emotionalWeight = Int($0) }
                        ), in: 1...5, step: 1)
                        Text("Heavy")
                            .font(.caption)
                    }
                    HStack {
                        ForEach(0..<emotionalWeight, id: \.self) { _ in
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("Time Spent")) {
                    Stepper("\(timeSpent) minutes", value: $timeSpent, in: 5...300, step: 5)
                }
                
                Section(header: Text("Was this work visible/recognized?")) {
                    Toggle("Visible to others", isOn: $wasVisible)
                    Text("Most emotional labor remains invisible")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("Notes (optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("Log Care Labor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let entry = CareEntry(
                            taskType: selectedTaskType,
                            recipientType: selectedRecipient,
                            emotionalWeight: emotionalWeight,
                            timeSpent: timeSpent,
                            notes: notes,
                            wasVisible: wasVisible
                        )
                        dataManager.addEntry(entry)
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Insights View
struct InsightsView: View {
    @ObservedObject var dataManager: CareDataManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    HStack(spacing: 15) {
                        InsightCard(
                            title: "Total Hours",
                            value: String(format: "%.1f", dataManager.totalHours),
                            icon: "clock.fill",
                            color: .blue
                        )
                        
                        InsightCard(
                            title: "Invisible Hours",
                            value: String(format: "%.1f", dataManager.invisibleHours),
                            icon: "eye.slash.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    // Hochschild Quote
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Making the Invisible Visible")
                            .font(.headline)
                        Text("\"The work requires one to induce or suppress feeling in order to sustain the outward countenance that produces the proper state of mind in others.\"")
                            .font(.caption)
                            .italic()
                            .foregroundColor(.gray)
                        Text("— Arlie Hochschild")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Task breakdown
                    if !dataManager.entries.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Care Work Breakdown")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(CareTaskType.allCases, id: \.self) { type in
                                let count = dataManager.entries.filter { $0.taskType == type }.count
                                if count > 0 {
                                    HStack {
                                        Image(systemName: type.icon)
                                            .foregroundColor(.blue)
                                        Text(type.rawValue)
                                        Spacer()
                                        Text("\(count)")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Insights")
        }
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            Text(value)
                .font(.title)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Commons View
struct CommonsView: View {
    @ObservedObject var dataManager: CareDataManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Federici Quote
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Building Care Commons")
                            .font(.headline)
                        Text("\"The commons is not a gated reality. It is a social system that creates access to shared wealth and forms of cooperation.\"")
                            .font(.caption)
                            .italic()
                            .foregroundColor(.gray)
                        Text("— Silvia Federici")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your Care Labor as Data Commons")
                            .font(.headline)
                        
                        Text("This ledger makes your invisible labor visible—not for extraction, but for collective recognition.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("Future iterations could:")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 5)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            BulletPoint(text: "Allow anonymous sharing of care patterns")
                            BulletPoint(text: "Create peer support networks")
                            BulletPoint(text: "Advocate for institutional recognition")
                            BulletPoint(text: "Build reciprocal care exchanges")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Gift Economy Principles")
                            .font(.headline)
                        
                        Text("Like Kimmerer's strawberries, care labor circulates through gift relationships—not commodified exchanges.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("This app refuses to:")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 5)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            BulletPoint(text: "Gamify care (no points/achievements)")
                            BulletPoint(text: "Extract your data for profit")
                            BulletPoint(text: "Create productivity metrics")
                            BulletPoint(text: "Rank or compare caregivers")
                        }
                    }
                    .padding()
                    .background(Color.pink.opacity(0.05))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Care Commons")
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.subheadline)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Instructions View
struct InstructionsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Welcome to Care Labor Ledger")
                            .font(.title2)
                            .bold()
                        Text("A tool for making invisible emotional labor visible")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Why use this app
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Why Track Care Labor?")
                                .font(.headline)
                        }
                        
                        Text("Most emotional labor goes unrecognized. This app helps you:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            InstructionPoint(icon: "eye.fill", text: "Make invisible work visible")
                            InstructionPoint(icon: "chart.bar.fill", text: "Quantify your emotional labor")
                            InstructionPoint(icon: "heart.circle.fill", text: "Validate your care work")
                            InstructionPoint(icon: "hand.raised.fill", text: "Set boundaries around your energy")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
                    
                    // How to log an entry
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("How to Log Care Labor")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            StepView(number: "1", text: "Tap the + button in the Ledger tab")
                            StepView(number: "2", text: "Select the type of care work you did")
                            StepView(number: "3", text: "Choose who you did it for")
                            StepView(number: "4", text: "Rate the emotional weight (1-5)")
                            StepView(number: "5", text: "Enter time spent")
                            StepView(number: "6", text: "Toggle whether it was visible/recognized")
                            StepView(number: "7", text: "Add notes (optional)")
                            StepView(number: "8", text: "Tap Save")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
                    
                    // Understanding the tabs
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "rectangle.3.group.fill")
                                .foregroundColor(.green)
                            Text("Understanding the Tabs")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            TabDescription(
                                icon: "book.fill",
                                title: "Ledger",
                                description: "View all your logged care labor entries. Swipe left to delete entries."
                            )
                            
                            TabDescription(
                                icon: "chart.bar.fill",
                                title: "Insights",
                                description: "See statistics about your care work, including total hours and invisible labor."
                            )
                            
                            TabDescription(
                                icon: "questionmark.circle.fill",
                                title: "Instructions",
                                description: "You're here! Reference these instructions anytime."
                            )
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
                    
                    // Types of care work
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "list.bullet.circle.fill")
                                .foregroundColor(.purple)
                            Text("Types of Care Work")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            CareTypeExample(icon: "heart.fill", type: "Emotional Support", example: "Comforting a friend after bad news")
                            CareTypeExample(icon: "person.3.fill", type: "Group Project Labor", example: "Organizing meetings, mediating conflicts")
                            CareTypeExample(icon: "book.fill", type: "Peer Mentoring", example: "Helping someone understand coursework")
                            CareTypeExample(icon: "house.fill", type: "Space Tending", example: "Cleaning shared spaces, creating welcoming environments")
                            CareTypeExample(icon: "bubble.left.and.bubble.right.fill", type: "Conflict Mediation", example: "Helping roommates resolve disagreements")
                            CareTypeExample(icon: "calendar", type: "Admin/Organizing", example: "Planning events, coordinating schedules")
                            CareTypeExample(icon: "globe", type: "Cultural Translation", example: "Bridging cultural differences, explaining contexts")
                            CareTypeExample(icon: "ear.fill", type: "Active Listening", example: "Being fully present for someone's struggles")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
                    
                }
                .padding()
            }
            .navigationTitle("Instructions")
        }
    }
}

struct InstructionPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct StepView: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.subheadline)
                .bold()
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

struct TabDescription: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct CareTypeExample: View {
    let icon: String
    let type: String
    let example: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type)
                    .font(.subheadline)
                    .bold()
                Text("Ex: \(example)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 2)
    }
}
