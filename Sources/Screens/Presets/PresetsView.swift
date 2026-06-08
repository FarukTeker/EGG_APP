import SwiftUI

// MARK: - UC-09, UC-12, UC-13: Presets Tab

struct PresetsTabView: View {
    @EnvironmentObject private var store: AppStore
    @State private var editingPreset: EggPreset? = nil
    @State private var showEditor = false
    @State private var showSchedules = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgApp.ignoresSafeArea()
                if store.presets.isEmpty {
                    EmptyPresetsView()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(store.presets) { preset in
                                PresetCard(preset: preset) {
                                    editingPreset = preset
                                    showEditor = true
                                }
                            }
                            VPresetPill(title: "+ Add Preset", isGhost: true) {
                                editingPreset = nil
                                showEditor = true
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Presets").font(.vestelH3).foregroundStyle(Color.fg1)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSchedules = true } label: {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(store.scheduledCooks.isEmpty ? Color.fg3 : Color.brandYellow)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editingPreset = nil; showEditor = true } label: {
                        Image(systemName: "plus").foregroundStyle(Color.brandYellow)
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                PresetEditorView(preset: editingPreset)
            }
            .sheet(isPresented: $showSchedules) {
                ScheduleListSheet()
            }
        }
    }
}

private struct PresetCard: View {
    let preset: EggPreset
    var onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(preset.name).font(.vestelH3).foregroundStyle(Color.fg1)
                Spacer()
                Button { onEdit() } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.fg3)
                        .frame(width: 32, height: 32)
                }
            }
            Text(preset.summaryText)
                .font(.vestelCaption)
                .foregroundStyle(Color.fg2)
            HStack {
                Label(preset.mode == .bulk ? "Bulk" : "Separate", systemImage: "circle.hexagongrid")
                    .font(.vestelCaption)
                    .foregroundStyle(Color.fg3)
                Spacer()
                Text("\(preset.selectedEggs.count) eggs")
                    .font(.vestelCaption)
                    .foregroundStyle(Color.fg3)
            }
        }
        .padding(16)
        .background(Color.bgSurface1)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 24)
    }
}

// MARK: - Empty Presets (UC-21 error state)

struct EmptyPresetsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showEditor = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.fg3)
            Text("No presets yet").font(.vestelH3).foregroundStyle(Color.fg1)
            Text("Save your favourite combo once and re-run it with a tap.")
                .font(.vestelCaption).foregroundStyle(Color.fg2)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            Spacer()
            VBtn(title: "Create preset") { showEditor = true }
                .padding(.horizontal, 24).padding(.bottom, 40)
        }
        .sheet(isPresented: $showEditor) { PresetEditorView(preset: nil) }
    }
}

// MARK: - UC-12: Preset Editor

struct PresetEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let existingPreset: EggPreset?

    @State private var name: String
    @State private var mode: CookMode
    @State private var selectedEggs: Set<Int>
    @State private var donenessLevels: [String]
    @State private var showDeleteAlert = false
    @State private var showShare = false
    @State private var showScheduleEditor = false
    @State private var savedPresetForSchedule: EggPreset? = nil

    init(preset: EggPreset?) {
        self.existingPreset = preset
        _name = State(initialValue: preset?.name ?? "")
        _mode = State(initialValue: preset?.mode ?? .bulk)
        _selectedEggs = State(initialValue: Set(preset?.selectedEggs ?? [0, 1, 2, 3, 4, 5]))
        _donenessLevels = State(initialValue: preset?.donenessLevels ?? ["Medium", "Medium", "Medium"])
    }

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: existingPreset == nil ? "New Preset" : "Edit Preset",
                           onBack: { dismiss() },
                           trailingIcon: existingPreset != nil ? "square.and.arrow.up" : nil,
                           onTrailing: { showShare = true })

                ScrollView {
                    VStack(spacing: 18) {
                        VInput(placeholder: "Preset name", text: $name)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        Text("Mode")
                            .font(.vestelCaption)
                            .foregroundStyle(Color.fg3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                        VSeg(options: ["Bulk", "Separate"],
                             active: Binding(get: { mode == .bulk ? "Bulk" : "Separate" },
                                              set: { mode = $0 == "Bulk" ? .bulk : .separate }))
                            .padding(.horizontal, 24)

                        Text("Eggs")
                            .font(.vestelCaption)
                            .foregroundStyle(Color.fg3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                        VEggGrid(selected: $selectedEggs)
                            .padding(.horizontal, 24)

                        if mode == .bulk {
                            VDonenessBulk(active: Binding(
                                get: { donenessLevels[0] },
                                set: { v in donenessLevels = [v, v, v] }
                            ), caption: "All blocks · same level")
                            .padding(.horizontal, 24)
                        } else {
                            VDonenessSeparate(levels: $donenessLevels,
                                              selectedEggs: selectedEggs,
                                              caption: "Per block · own level")
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 20)
                }

                VStack(spacing: 12) {
                    VBtn(title: "Save") {
                        var preset = existingPreset ?? EggPreset(
                            name: name, mode: mode,
                            selectedEggs: Array(selectedEggs).sorted(),
                            donenessLevels: donenessLevels)
                        preset.name = name.isEmpty ? "My Preset" : name
                        preset.mode = mode
                        preset.selectedEggs = Array(selectedEggs).sorted()
                        preset.donenessLevels = donenessLevels
                        store.savePreset(preset)
                        dismiss()
                    }
                    VBtn(title: "Schedule this preset", kind: .ghost) {
                        // Save first, then open scheduler with this preset
                        var preset = existingPreset ?? EggPreset(
                            name: name, mode: mode,
                            selectedEggs: Array(selectedEggs).sorted(),
                            donenessLevels: donenessLevels)
                        preset.name = name.isEmpty ? "My Preset" : name
                        preset.mode = mode
                        preset.selectedEggs = Array(selectedEggs).sorted()
                        preset.donenessLevels = donenessLevels
                        store.savePreset(preset)
                        savedPresetForSchedule = preset
                        showScheduleEditor = true
                    }
                    if existingPreset != nil {
                        VBtn(title: "Delete preset", kind: .dangerOutline) { showDeleteAlert = true }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .alert("Delete \"\(existingPreset?.name ?? "")\"?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let p = existingPreset { store.deletePreset(p) }
                dismiss()
            }
        } message: {
            Text("This preset will be removed. Scheduled cooks using it will be cancelled.")
        }
        .sheet(isPresented: $showShare) {
            if let p = existingPreset { SharePresetView(preset: p) }
        }
        .sheet(isPresented: $showScheduleEditor) {
            if let p = savedPresetForSchedule {
                ScheduleEditorSheet(preselectedPreset: p) { newSchedule in
                    store.addSchedule(newSchedule)
                }
            }
        }
    }
}

// MARK: - UC-13: Share Preset

struct SharePresetView: View {
    @Environment(\.dismiss) private var dismiss
    let preset: EggPreset

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Share preset", onBack: { dismiss() })

                Spacer()

                Text("Anyone in your household can scan this to add ")
                    .font(.vestelCaption).foregroundStyle(Color.fg2) +
                Text(preset.name).bold().font(.vestelCaption).foregroundStyle(Color.fg1) +
                Text(".")

                // QR placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.bgSurface1)
                    .frame(width: 160, height: 160)
                    .overlay(
                        Image(systemName: "qrcode")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.fg2)
                    )
                    .padding(.vertical, 20)

                Text("Code: GRNDM-FAV-9132")
                    .font(.vestelCaption).foregroundStyle(Color.fg3)

                Spacer()

                VStack(spacing: 12) {
                    VBtn(title: "Share link") { }
                    VBtn(title: "Copy code", kind: .ghost) {
                        UIPasteboard.general.string = "GRNDM-FAV-9132"
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Schedule List Sheet

struct ScheduleListSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var showEditor = false
    @State private var editingSchedule: ScheduledCook? = nil

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Scheduled Cooks",
                           onBack: { dismiss() },
                           trailingIcon: "plus",
                           onTrailing: { editingSchedule = nil; showEditor = true })

                if store.scheduledCooks.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 48)).foregroundStyle(Color.fg3)
                        Text("No schedules").font(.vestelH3).foregroundStyle(Color.fg1)
                        Text("Schedule a preset to cook automatically at a set time.")
                            .font(.vestelCaption).foregroundStyle(Color.fg2)
                            .multilineTextAlignment(.center).padding(.horizontal, 40)
                    }
                    Spacer()
                    VBtn(title: "Add schedule") { editingSchedule = nil; showEditor = true }
                        .padding(.horizontal, 24).padding(.bottom, 40)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(store.scheduledCooks) { schedule in
                                ScheduleRow(schedule: schedule) {
                                    editingSchedule = schedule
                                    showEditor = true
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            if let s = editingSchedule {
                ScheduleEditorSheet(schedule: s) { updated in
                    store.updateSchedule(updated)
                }
            } else {
                ScheduleEditorSheet(preselectedPreset: store.presets.first) { newSchedule in
                    store.addSchedule(newSchedule)
                }
            }
        }
    }
}

private struct ScheduleRow: View {
    @EnvironmentObject private var store: AppStore
    let schedule: ScheduledCook
    var onEdit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.preset.name)
                        .font(.vestelBody).foregroundStyle(Color.fg1)
                    Text(schedule.summaryLine)
                        .font(.vestelCaption).foregroundStyle(Color.fg3)
                    Text(schedule.scheduleType.rawValue)
                        .font(.vestelCaption).foregroundStyle(schedule.isEnabled ? Color.brandYellow : Color.fg3)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { schedule.isEnabled },
                    set: { enabled in
                        var s = schedule; s.isEnabled = enabled
                        store.updateSchedule(s)
                    }))
                    .tint(.brandYellow)
                    .labelsHidden()
                Button { onEdit() } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fg3)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            Divider().background(Color.line1).padding(.horizontal, 24)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { store.deleteSchedule(schedule) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Schedule Editor Sheet

struct ScheduleEditorSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var schedule: ScheduledCook? = nil
    var preselectedPreset: EggPreset? = nil
    var onSave: (ScheduledCook) -> Void

    @State private var scheduleType: ScheduledCook.ScheduleType = .oneTime
    @State private var fireTime: Date
    @State private var oneTimeDate: Date
    @State private var weekdays: [Int] = [2, 5]   // Mon, Thu default
    @State private var selectedPreset: EggPreset? = nil
    @State private var showPresetPicker = false

    init(schedule: ScheduledCook? = nil,
         preselectedPreset: EggPreset? = nil,
         onSave: @escaping (ScheduledCook) -> Void) {
        self.schedule = schedule
        self.preselectedPreset = preselectedPreset
        self.onSave = onSave

        let defaultTime: Date = {
            var c = DateComponents(); c.hour = 7; c.minute = 30
            return Calendar.current.date(from: c) ?? Date()
        }()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        if let s = schedule {
            _scheduleType  = State(initialValue: s.scheduleType)
            _fireTime      = State(initialValue: s.fireTime)
            _oneTimeDate   = State(initialValue: s.oneTimeDate ?? tomorrow)
            _weekdays      = State(initialValue: s.weekdays)
            _selectedPreset = State(initialValue: s.preset)
        } else {
            _fireTime      = State(initialValue: defaultTime)
            _oneTimeDate   = State(initialValue: tomorrow)
            _selectedPreset = State(initialValue: preselectedPreset)
        }
    }

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: schedule == nil ? "New Schedule" : "Edit Schedule", onBack: { dismiss() })

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Preset picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preset").font(.vestelCaption).foregroundStyle(Color.fg3)
                            Button { showPresetPicker = true } label: {
                                HStack {
                                    Text(selectedPreset?.name ?? "Choose a preset…")
                                        .font(.vestelBody)
                                        .foregroundStyle(selectedPreset == nil ? Color.fg3 : Color.fg1)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12)).foregroundStyle(Color.fg3)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                                .background(Color.bgSurface1)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.horizontal, 24)

                        // Schedule type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Repeat").font(.vestelCaption).foregroundStyle(Color.fg3)
                                .padding(.horizontal, 24)
                            VSeg(options: ScheduledCook.ScheduleType.allCases.map { $0.rawValue },
                                 active: Binding(
                                    get: { scheduleType.rawValue },
                                    set: { scheduleType = ScheduledCook.ScheduleType(rawValue: $0) ?? .oneTime }
                                 ))
                                .padding(.horizontal, 24)
                        }

                        // Date (one-time only)
                        if scheduleType == .oneTime {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Date").font(.vestelCaption).foregroundStyle(Color.fg3)
                                    .padding(.horizontal, 24)
                                DatePicker("", selection: $oneTimeDate, in: Date()..., displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .tint(Color.brandYellow)
                                    .padding(.horizontal, 16)
                                    .background(Color.bgSurface1)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .padding(.horizontal, 24)
                                    .colorScheme(.dark)
                            }
                        }

                        // Weekdays (weekly only)
                        if scheduleType == .weekly {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Days").font(.vestelCaption).foregroundStyle(Color.fg3)
                                    .padding(.horizontal, 24)
                                WeekdaySelector(selected: $weekdays)
                                    .padding(.horizontal, 24)
                            }
                        }

                        // Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Time").font(.vestelCaption).foregroundStyle(Color.fg3)
                                .padding(.horizontal, 24)
                            DatePicker("", selection: $fireTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .tint(Color.brandYellow)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 24)
                                .colorScheme(.dark)
                        }
                    }
                    .padding(.vertical, 16)
                }

                VBtn(title: "Save Schedule") {
                    guard let preset = selectedPreset else { return }
                    let s = ScheduledCook(
                        id: schedule?.id ?? UUID(),
                        preset: preset,
                        scheduleType: scheduleType,
                        fireTime: fireTime,
                        oneTimeDate: scheduleType == .oneTime ? oneTimeDate : nil,
                        weekdays: scheduleType == .weekly ? weekdays : [],
                        isEnabled: true)
                    onSave(s)
                    dismiss()
                }
                .disabled(selectedPreset == nil || (scheduleType == .weekly && weekdays.isEmpty))
                .padding(.horizontal, 24).padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showPresetPicker) {
            PresetPickerForSchedule(selected: $selectedPreset)
        }
    }
}

// MARK: - Preset picker for schedule editor

private struct PresetPickerForSchedule: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: EggPreset?

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Choose Preset", onBack: { dismiss() })
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(store.presets) { preset in
                            Button {
                                selected = preset
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(preset.name).font(.vestelBody).foregroundStyle(Color.fg1)
                                        Text(preset.summaryText).font(.vestelCaption).foregroundStyle(Color.fg3)
                                    }
                                    Spacer()
                                    if selected?.id == preset.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.brandYellow)
                                    }
                                }
                                .padding(.horizontal, 24).padding(.vertical, 14)
                            }
                            Divider().background(Color.line1).padding(.horizontal, 24)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Weekday Selector

struct WeekdaySelector: View {
    @Binding var selected: [Int]

    // Display order: Mon..Sun, (id follows Calendar.weekday: 1=Sun 2=Mon..7=Sat)
    private let days: [(id: Int, label: String)] = [
        (2,"M"),(3,"T"),(4,"W"),(5,"T"),(6,"F"),(7,"S"),(1,"S")
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(days, id: \.id) { day in
                let active = selected.contains(day.id)
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if active { selected.removeAll { $0 == day.id } }
                        else { selected.append(day.id) }
                    }
                } label: {
                    Text(day.label)
                        .font(.vestelLabel)
                        .foregroundStyle(active ? .white : Color.fg2)
                        .frame(width: 38, height: 38)
                        .background(active ? Color.brandYellow : Color.bgSurface2)
                        .clipShape(Circle())
                }
            }
        }
    }
}
