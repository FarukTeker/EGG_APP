import SwiftUI

// MARK: - UC-06, UC-07: Main Cook Screen

struct MainCookView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showSchedule = false
    @State private var scheduleConfirm: String? = nil

    private var canStart: Bool { !store.selectedEggs.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            VTopbar()

            ScrollView {
                VStack(spacing: 18) {
                    // Ring timer (idle state) — enlarged to match Figma
                    let activeLevels = (0..<3)
                        .filter { store.selectedEggs.contains($0 * 2) || store.selectedEggs.contains($0 * 2 + 1) }
                        .map { store.donenessLevels[$0] }
                    let donenessMin = store.cookMode == .bulk
                        ? donenessTime(store.donenessLevels[0])
                        : donenessTime(activeLevels.max(by: { donenessOrder($0) < donenessOrder($1) }) ?? "Medium")
                    VRing(big: timeStr(donenessMin * 60), sub: "until done", progress: 0, radius: 92)
                        .padding(.top, 12)

                    // Schedule confirmation (auto-hides)
                    if let msg = scheduleConfirm {
                        VBanner(message: "Cook scheduled", detail: msg, tone: .success)
                            .padding(.horizontal, 24)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Low water warning
                    let maxLevel = (store.cookMode == .bulk ? [store.donenessLevels[0]] : activeLevels)
                        .max(by: { phaseDonenessOrder($0) < phaseDonenessOrder($1) }) ?? "Medium"
                    let minWater = maxLevel == "Hard" ? 0.33 : maxLevel == "Medium" ? 0.22 : 0.15
                    if store.waterLevel < minWater {
                        VBanner(message: "Low water",
                                detail: "Refill the tank before starting this program.",
                                tone: .warning)
                            .padding(.horizontal, 24)
                    }

                    // Bulk / Separate toggle — bound directly to store to stay in sync
                    VSeg(options: ["Bulk", "Separate"], active: Binding(
                        get: { store.cookMode == .bulk ? "Bulk" : "Separate" },
                        set: { store.cookMode = $0 == "Bulk" ? .bulk : .separate }
                    ))
                        .padding(.horizontal, 24)

                    // Egg Grid — hardness picked via the per-compartment label dropdown
                    VEggGrid(selected: $store.selectedEggs,
                             doneness: $store.donenessLevels,
                             bulkMode: store.cookMode == .bulk)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)
            }

            // Bottom action bar: Schedule (hourglass) + Start
            HStack(spacing: 12) {
                Button { showSchedule = true } label: {
                    Image(systemName: "hourglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(canStart ? .white : Color.fgDisabled)
                        .frame(width: 52, height: 52)
                        .background(canStart ? Color.brandYellow : Color.bgSurface2)
                        .clipShape(Circle())
                }
                .disabled(!canStart)

                VBtn(title: "Start") { store.startCook() }
                    .opacity(canStart ? 1 : 0.5)
                    .disabled(!canStart)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.bgApp.ignoresSafeArea())
        .sheet(isPresented: $showSchedule) {
            ScheduleCookSheet { confirmation in
                withAnimation { scheduleConfirm = confirmation }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { scheduleConfirm = nil }
                }
            }
        }
    }

    private func donenessTime(_ level: String) -> Int {
        switch level { case "Soft": return 4; case "Rare": return 5; case "Medium": return 6; case "Hard": return 9; default: return 6 }
    }
    private func donenessOrder(_ level: String) -> Int {
        switch level { case "Soft": return 1; case "Rare": return 2; case "Medium": return 3; case "Hard": return 4; default: return 0 }
    }
    private func timeStr(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Schedule Cook Sheet (next-24h, one-time)

struct ScheduleCookSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var time = Date()
    var onScheduled: (String) -> Void

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Schedule cook", onBack: { dismiss() })

                Text("Cooks the selected compartments at the chosen time, within the next 24 hours.")
                    .font(.vestelCaption)
                    .foregroundStyle(Color.fg2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)

                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding(.top, 16)

                Spacer()

                VBtn(title: "Schedule", systemImage: "hourglass") {
                    let fire = store.scheduleWithin24h(at: time)
                    onScheduled(confirmationText(for: fire))
                    dismiss()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func confirmationText(for fire: Date) -> String {
        let cal = Calendar.current
        let day = cal.isDateInToday(fire) ? "Today"
                : cal.isDateInTomorrow(fire) ? "Tomorrow"
                : fire.formatted(.dateTime.weekday(.abbreviated))
        return "\(day) · \(fire.formatted(.dateTime.hour().minute()))"
    }
}

// MARK: - UC-08: Egg Style Picker

struct EggStyleView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var selected = "Medium"

    struct Style { let name: String; let subtitle: String; let icon: String }
    let styles: [Style] = [
        Style(name: "Soft",   subtitle: "Runny yolk · 4 min",         icon: "circle"),
        Style(name: "Rare",   subtitle: "Barely set yolk · 5 min",    icon: "circle.dotted"),
        Style(name: "Medium", subtitle: "Jammy yolk · 6 min",         icon: "circle.lefthalf.filled"),
        Style(name: "Hard",   subtitle: "Fully set · 9 min",          icon: "circle.fill")
    ]

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Egg Style", onBack: { dismiss() })
                Text("How do you like them?")
                    .font(.vestelH3)
                    .foregroundStyle(Color.fg1)
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                VStack(spacing: 10) {
                    ForEach(styles, id: \.name) { s in
                        HStack(spacing: 14) {
                            Image(systemName: s.icon)
                                .font(.system(size: 28))
                                .foregroundStyle(selected == s.name ? Color.brandYellow : Color.fg3)
                                .frame(width: 40)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(s.name).font(.vestelH3).foregroundStyle(Color.fg1)
                                Text(s.subtitle).font(.vestelCaption).foregroundStyle(Color.fg2)
                            }
                            Spacer()
                            if selected == s.name {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.brandYellow)
                            }
                        }
                        .padding(16)
                        .background(selected == s.name ? Color.brandYellowSoft : Color.bgSurface1)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(selected == s.name ? Color.brandYellow : Color.clear, lineWidth: 1.5))
                        .onTapGesture { selected = s.name }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                VBtn(title: "Continue") {
                    store.donenessLevels = [selected, selected, selected]
                    store.defaultStyle = selected
                    dismiss()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear { selected = store.donenessLevels[0] }
    }
}

// MARK: - Preset Picker Sheet

struct PresetPickerSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                VNavHeader(title: "Presets", onBack: { dismiss() })
                    .padding(.top, 8)

                if store.presets.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "circle.hexagongrid.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.fg3)
                        Text("No presets yet").font(.vestelH3).foregroundStyle(Color.fg1)
                        Text("Save a cook as preset to reuse it.").font(.vestelCaption).foregroundStyle(Color.fg2)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(store.presets) { preset in
                                Button {
                                    store.applyPreset(preset)
                                    dismiss()
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(preset.name).font(.vestelBody).foregroundStyle(Color.fg1)
                                            Text(preset.summaryText).font(.vestelCaption).foregroundStyle(Color.fg3)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.fg3)
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 24)
                                }
                                Divider().background(Color.line1)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UC-11: Cooking Active View

struct CookingActiveView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            VTopbar()

            Spacer()

            // Centered, enlarged ring — the compartment picker fades out while cooking
            if case .active(let remaining, let total) = store.cookingState {
                let progress = total > 0 ? Double(total - remaining) / Double(total) : 0
                let phases = buildRingPhases(mode: store.cookMode,
                                             levels: store.donenessLevels,
                                             eggs: store.selectedEggs)
                let display = phaseTimerDisplay(remaining: remaining, total: total,
                                                mode: store.cookMode,
                                                levels: store.donenessLevels,
                                                eggs: store.selectedEggs)
                VRing(big: display.big,
                      sub: store.isPaused ? "paused" : display.sub,
                      progress: progress,
                      phases: phases,
                      radius: 120)
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            VStack(spacing: 12) {
                VBtn(title: store.isPaused ? "Resume" : "Pause",
                     systemImage: store.isPaused ? "play.fill" : "pause.fill") {
                    if store.isPaused { store.resumeCook() } else { store.pauseCook() }
                }
                VBtn(title: "Stop", systemImage: "stop.fill") {
                    store.cancelCook()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.bgApp.ignoresSafeArea())
    }
}

// MARK: - UC-11: Cooking Complete View

struct CookingCompleteView: View {
    @EnvironmentObject private var store: AppStore
    let session: CookSession
    @State private var showPresetNameSheet = false
    @State private var presetName = ""

    var body: some View {
        VStack(spacing: 0) {
            VTopbar()
            Spacer()

            VBigIcon(systemName: "checkmark", tone: .success)
            Text("Your eggs are ready")
                .font(.vestelH2)
                .foregroundStyle(Color.fg1)
                .padding(.top, 16)
            Text(session.historyDetail)
                .font(.vestelCaption)
                .foregroundStyle(Color.fg2)
                .padding(.top, 4)

            Text("00:00")
                .font(.vestelDisplay)
                .foregroundStyle(Color.fg1)
                .padding(.top, 20)
            Text("Cooked for \(cookTimeStr)")
                .font(.vestelCaption)
                .foregroundStyle(Color.fg3)

            Spacer()

            VStack(spacing: 12) {
                VBtn(title: "Cook again") { store.cookAgain() }
                VBtn(title: "Save as preset", kind: .ghost) { showPresetNameSheet = true }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.bgApp.ignoresSafeArea())
        .sheet(isPresented: $showPresetNameSheet) {
            SavePresetSheet { name in
                store.saveAsPreset(name: name)
            }
        }
    }

    private var cookTimeStr: String {
        guard let start = session.completedAt else { return "—" }
        let seconds = Int(start.timeIntervalSince(session.startedAt))
        let m = seconds / 60
        return "\(m) min"
    }
}

private struct SavePresetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    var onSave: (String) -> Void

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Name your preset").font(.vestelH3).foregroundStyle(Color.fg1).padding(.top, 32)
                VInput(placeholder: "e.g. Sunday Brunch", text: $name)
                    .padding(.horizontal, 24)
                Spacer()
                VStack(spacing: 12) {
                    VBtn(title: "Save") {
                        onSave(name.isEmpty ? "My Preset" : name)
                        dismiss()
                    }
                    VBtn(title: "Cancel", kind: .ghost) { dismiss() }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - UC-19: Device Offline

struct DeviceOfflineView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            VTopbar()
            Spacer()
            VBigIcon(systemName: "wifi.slash", tone: .warning)
            Text("Cooker is offline")
                .font(.vestelH2).foregroundStyle(Color.fg1).padding(.top, 16)
            Group {
                Text("We can't reach ") +
                Text(store.activeDevice?.name ?? "your device").bold() +
                Text(". Check that it's powered on and connected to Wi-Fi.")
            }
            .font(.vestelCaption).foregroundStyle(Color.fg2)
            .multilineTextAlignment(.center).padding(.horizontal, 40).padding(.top, 10)

            VBanner(message: "Wi-Fi: Vestel-Home", tone: .warning)
                .padding(.horizontal, 24).padding(.top, 20)

            Spacer()
            VStack(spacing: 12) {
                VBtn(title: "Reconnect") { store.cookingState = .idle }
                VBtn(title: "Switch device", kind: .ghost) { store.cookingState = .idle }
            }
            .padding(.horizontal, 24).padding(.bottom, 40)
        }
        .background(Color.bgApp.ignoresSafeArea())
    }
}

// MARK: - UC-20: Wi-Fi Lost Mid-Cook

struct WifiLostView: View {
    @EnvironmentObject private var store: AppStore
    let remainingSeconds: Int

    var body: some View {
        VStack(spacing: 0) {
            VTopbar()
            VBanner(message: "Connection lost", detail: "Cook continues on the device", tone: .warning)
                .padding(.horizontal, 24).padding(.top, 12)
            VRing(big: timeStr(remainingSeconds), sub: "left", progress: 0.62)
                .padding(.top, 16)
            Spacer()
            VBtn(title: "Try to reconnect", kind: .ghost) { store.cookingState = .idle }
                .padding(.horizontal, 24).padding(.bottom, 40)
        }
        .background(Color.bgApp.ignoresSafeArea())
    }
    private func timeStr(_ s: Int) -> String { String(format: "%d:%02d", s / 60, s % 60) }
}


// MARK: - UC-21: No Eggs Detected

struct NoEggsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            VTopbar()
            VRing(big: "—:—", sub: "empty", progress: 0).padding(.top, 16)
            VBanner(message: "No eggs detected", detail: "Place at least one egg in any section.", tone: .warning)
                .padding(.horizontal, 24).padding(.top, 12)
            VSeg(options: ["Bulk", "Separate"],
                 active: .constant(store.cookMode == .bulk ? "Bulk" : "Separate"))
                .disabled(true)
                .padding(.horizontal, 24).padding(.top, 16)
            VEggGrid(selected: .constant(Set<Int>()), interactive: false)
                .padding(.horizontal, 24).padding(.top, 12)
            Spacer()
            VStack(spacing: 12) {
                VBtn(title: "Start anyway", kind: .ghost) {
                    store.selectedEggs = [0, 1]
                    store.startCook()
                }
                VBtn(title: "Go back", kind: .secondary) { store.cookingState = .idle }
            }
            .padding(.horizontal, 24).padding(.bottom, 40)
        }
        .background(Color.bgApp.ignoresSafeArea())
    }
}

// MARK: - Phase helpers (file-private)

private func phaseDonenessSeconds(_ level: String) -> Int {
    switch level { case "Soft": return 240; case "Rare": return 300; case "Medium": return 360; case "Hard": return 540; default: return 360 }
}

private func phaseDonenessOrder(_ level: String) -> Int {
    switch level { case "Soft": return 1; case "Rare": return 2; case "Medium": return 3; case "Hard": return 4; default: return 3 }
}

private func phaseLevelColor(_ level: String) -> Color {
    switch level {
    case "Soft":   return .info          // blue — fastest
    case "Rare":   return Color(hex: "26C4C4")  // teal
    case "Medium": return .accentOrange  // orange
    case "Hard":   return .brandRed      // red — slowest
    default:       return .accentOrange
    }
}

private func buildRingPhases(mode: CookMode, levels: [String], eggs: Set<Int>) -> [RingPhase] {
    let activeSections = (0..<3).filter { eggs.contains($0 * 2) || eggs.contains($0 * 2 + 1) }
    let rawLevels = mode == .bulk ? [levels[0]] : activeSections.map { levels[$0] }
    let uniqueSorted = Array(Set(rawLevels)).sorted { phaseDonenessOrder($0) < phaseDonenessOrder($1) }
    guard let maxSecs = uniqueSorted.map({ phaseDonenessSeconds($0) }).max(), maxSecs > 0 else { return [] }
    var result: [RingPhase] = []
    var prev = 0
    for level in uniqueSorted {
        let cum = phaseDonenessSeconds(level)
        if cum > prev {
            result.append(RingPhase(
                startFraction: Double(prev) / Double(maxSecs),
                endFraction: Double(cum) / Double(maxSecs),
                color: phaseLevelColor(level)))
            prev = cum
        }
    }
    return result
}

/// big = current-phase countdown; sub = "+N min NextLevel" or "left"
private func phaseTimerDisplay(remaining: Int, total: Int,
                                mode: CookMode, levels: [String],
                                eggs: Set<Int>) -> (big: String, sub: String) {
    let elapsed = total - remaining
    let activeSections = (0..<3).filter { eggs.contains($0 * 2) || eggs.contains($0 * 2 + 1) }
    let rawLevels = mode == .bulk ? [levels[0]] : activeSections.map { levels[$0] }
    let uniqueSorted = Array(Set(rawLevels)).sorted { phaseDonenessOrder($0) < phaseDonenessOrder($1) }
    let phases = uniqueSorted.map { (label: $0, cumSecs: phaseDonenessSeconds($0)) }

    guard let idx = phases.firstIndex(where: { elapsed < $0.cumSecs }) else {
        return (big: "0:00", sub: "done")
    }
    let cur = phases[idx]
    let phaseRemaining = cur.cumSecs - elapsed
    let sub: String
    if idx + 1 < phases.count {
        let next = phases[idx + 1]
        sub = "+\(( next.cumSecs - cur.cumSecs) / 60) min \(next.label)"
    } else {
        sub = "left"
    }
    return (big: cookTimeStr(phaseRemaining), sub: sub)
}

private func cookTimeStr(_ s: Int) -> String {
    String(format: "%d:%02d", s / 60, s % 60)
}
