import SwiftUI

// MARK: - UC-09, UC-12, UC-13: Presets Tab

struct PresetsTabView: View {
    @EnvironmentObject private var store: AppStore
    @State private var editingPreset: EggPreset? = nil
    @State private var showEditor = false

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
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editingPreset = nil; showEditor = true } label: {
                        Image(systemName: "plus").foregroundStyle(Color.brandRed)
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                PresetEditorView(preset: editingPreset)
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
                Text("\(preset.selectedSections.count * 2) eggs")
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
    @State private var selectedSections: Set<Int>
    @State private var donenessLevels: [String]
    @State private var showDeleteAlert = false
    @State private var showShare = false

    init(preset: EggPreset?) {
        self.existingPreset = preset
        _name = State(initialValue: preset?.name ?? "")
        _mode = State(initialValue: preset?.mode ?? .bulk)
        _selectedSections = State(initialValue: Set(preset?.selectedSections ?? [0, 1, 2]))
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

                        Text("Sections")
                            .font(.vestelCaption)
                            .foregroundStyle(Color.fg3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                        VEggGrid(selected: $selectedSections)
                            .padding(.horizontal, 24)

                        if mode == .bulk {
                            VDonenessBulk(active: Binding(
                                get: { donenessLevels[0] },
                                set: { v in donenessLevels = [v, v, v] }
                            ), caption: "All blocks · same level")
                            .padding(.horizontal, 24)
                        } else {
                            VDonenessSeparate(levels: $donenessLevels,
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
                            selectedSections: Array(selectedSections).sorted(),
                            donenessLevels: donenessLevels)
                        preset.name = name.isEmpty ? "My Preset" : name
                        preset.mode = mode
                        preset.selectedSections = Array(selectedSections).sorted()
                        preset.donenessLevels = donenessLevels
                        store.savePreset(preset)
                        dismiss()
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
                VNavHeader(title: "Share preset") { dismiss() }

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
