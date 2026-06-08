import SwiftUI
import UIKit

// MARK: - Design Tokens (Vestel-Wireframes-standalone-2.html)

extension Color {
    /// Resolves to `light` or `dark` depending on the active interface style —
    /// driven by `.preferredColorScheme`, not just the system setting.
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    // Backgrounds
    static let bgApp      = adaptive(light: Color(hex: "EEE7E1"), dark: Color(hex: "1B1B1D"))
    static let bgSurface1 = adaptive(light: Color(hex: "E2DCD5"), dark: Color(hex: "2A2A2C"))
    static let bgSurface2 = adaptive(light: Color(hex: "D6CFC6"), dark: Color(hex: "3A3A3D"))
    static let bgSurface3 = adaptive(light: Color(hex: "CAC1B7"), dark: Color(hex: "4A4A4D"))

    // Text
    static let fg1        = adaptive(light: Color(hex: "2B2B2B"), dark: Color.white)
    static let fg2        = adaptive(light: Color(hex: "6B6B6B"), dark: Color(hex: "B8B8BA"))
    static let fg3        = adaptive(light: Color(hex: "9B9B9B"), dark: Color(hex: "7A7A7C"))
    static let fgDisabled = adaptive(light: Color(hex: "B5B5B5"), dark: Color(hex: "5A5A5C"))

    // Brand & accent
    static let brandRed      = Color(hex: "E72325")
    static let brandYellow      = Color(hex: "F8A838")
    static let brandYellowPress = Color(hex: "D88E20")
    static let brandYellowSoft  = adaptive(light: Color(hex: "FBE2BB"), dark: Color(hex: "3D2C0E"))
    static let accentOrange  = Color(hex: "F58025")

    // Semantic
    static let success = Color(hex: "2BB673")
    static let warning = Color(hex: "F5B400")
    static let info    = Color(hex: "4A8DFF")

    // Hairlines
    static let line1 = adaptive(light: Color.black.opacity(0.08), dark: Color.white.opacity(0.08))
    static let line2 = adaptive(light: Color.black.opacity(0.16), dark: Color.white.opacity(0.16))

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Typography helpers

extension Font {
    static let vestelDisplay = Font.system(size: 44, weight: .bold, design: .default)
    static let vestelH1      = Font.system(size: 22, weight: .bold)
    static let vestelH2      = Font.system(size: 18, weight: .semibold)
    static let vestelH3      = Font.system(size: 16, weight: .semibold)
    static let vestelBody    = Font.system(size: 14, weight: .regular)
    static let vestelLabel   = Font.system(size: 13, weight: .medium)
    static let vestelCaption = Font.system(size: 11, weight: .regular)
    static let vestelButton  = Font.system(size: 14, weight: .semibold)
}

// MARK: - Primitive Components

struct VBtn: View {
    enum Kind { case primary, secondary, ghost, dangerOutline }
    let title: String
    var kind: Kind = .primary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.vestelButton)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(background)
                .foregroundStyle(foreground)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(borderColor, lineWidth: borderWidth))
        }
    }

    private var background: Color {
        switch kind {
        case .primary:      return .brandYellow
        case .secondary:    return .bgSurface1
        case .ghost:        return .clear
        case .dangerOutline: return .clear
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary:      return .white
        case .secondary:    return .fg1
        case .ghost:        return .fg2
        case .dangerOutline: return .brandYellow
        }
    }

    private var borderColor: Color {
        switch kind {
        case .dangerOutline: return .brandYellow
        case .ghost:        return .line2
        default:            return .clear
        }
    }

    private var borderWidth: CGFloat {
        switch kind {
        case .dangerOutline, .ghost: return 1
        default: return 0
        }
    }
}

struct VLinkBtn: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.vestelLabel)
                .foregroundStyle(Color.fg2)
        }
    }
}

struct VInput: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .autocorrectionDisabled()
            }
        }
        .font(.vestelBody)
        .foregroundStyle(Color.fg1)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.bgSurface2)
        .clipShape(Capsule())
        .tint(.brandYellow)
        .textInputAutocapitalization(.never)
    }
}

struct VSeg: View {
    let options: [String]
    @Binding var active: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { opt in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { active = opt }
                } label: {
                    Text(opt)
                        .font(.vestelLabel)
                        .foregroundStyle(active == opt ? .white : Color.fg3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(active == opt ? Color.brandYellow : Color.clear)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(4)
        .background(Color.bgSurface2)
        .clipShape(Capsule())
    }
}

struct VTopbar: View {
    @EnvironmentObject private var store: AppStore
    var showAvatar: Bool = true
    var showBack: Bool = false
    var onBack: (() -> Void)? = nil
    @State private var showProfile = false

    var body: some View {
        HStack {
            if showBack {
                Button { onBack?() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.fg1)
                        .frame(width: 32, height: 32)
                }
            } else if showAvatar {
                Button { showProfile = true } label: {
                    Circle()
                        .fill(Color.bgSurface2)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "person")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.fg2)
                        )
                }
            } else {
                Spacer().frame(width: 32)
            }
            Spacer()
            VWaterButton()
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .sheet(isPresented: $showProfile) { ProfileOverviewView() }
    }
}

struct VNavHeader: View {
    let title: String
    var onBack: (() -> Void)? = nil
    var trailingIcon: String? = nil
    var onTrailing: (() -> Void)? = nil

    var body: some View {
        HStack {
            if let onBack {
                Button { onBack() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.fg1)
                        .frame(width: 32, height: 32)
                }
            } else {
                Spacer().frame(width: 32)
            }
            Spacer()
            Text(title).font(.vestelH3).foregroundStyle(Color.fg1)
            Spacer()
            if let icon = trailingIcon, let onTrailing {
                Button { onTrailing() } label: {
                    Image(systemName: icon)
                        .foregroundStyle(Color.brandYellow)
                        .frame(width: 32, height: 32)
                }
            } else {
                Spacer().frame(width: 32)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
}

// MARK: - Ring Phase Descriptor

struct RingPhase: Identifiable {
    let id = UUID()
    let startFraction: Double   // 0..1
    let endFraction: Double     // 0..1
    let color: Color
}

// MARK: - Ring Timer Component
// progress: 0..1 (0 = idle, 1 = complete)
// phases: empty → single accentOrange arc; populated → colored segments per cook level

struct VRing: View {
    let big: String
    let sub: String
    var progress: Double = 0
    var phases: [RingPhase] = []

    private let radius: CGFloat = 60

    var body: some View {
        ZStack {
            // Resting track — stays this gray-black tone wherever a bar has drained, and everywhere once done
            Circle()
                .stroke(Color.bgSurface2, lineWidth: 8)
                .frame(width: radius * 2, height: radius * 2)

            if phases.isEmpty {
                // Idle or fallback: plain arc, no dot
                if progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.accentOrange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: radius * 2, height: radius * 2)
                        .rotationEffect(.degrees(-90))
                }
            } else {
                // Each level's boundary dot sits at its end point from the very start, alongside
                // its full-color bar. As that level's time runs out, the bar drains toward the
                // dot — revealing the bare ring behind it — and the dot itself only disappears
                // once the bar has fully emptied into it.
                ForEach(phases) { phase in
                    let span = phase.endFraction - phase.startFraction
                    let drained = span > 0 ? clamp((progress - phase.startFraction) / span) : 1
                    let visibleStart = phase.startFraction + drained * span
                    if visibleStart < phase.endFraction {
                        Circle()
                            .trim(from: visibleStart, to: phase.endFraction)
                            .stroke(phase.color, style: StrokeStyle(lineWidth: 8, lineCap: .butt))
                            .frame(width: radius * 2, height: radius * 2)
                            .rotationEffect(.degrees(-90))
                    }
                }
                // Dots are drawn in a second pass, on top of every bar, so a neighbouring
                // phase's full-length bar never paints over a still-visible boundary dot.
                ForEach(phases) { phase in
                    let span = phase.endFraction - phase.startFraction
                    let drained = span > 0 ? clamp((progress - phase.startFraction) / span) : 1
                    if drained < 1 {
                        Circle()
                            .fill(phase.color)
                            .frame(width: 14, height: 14)
                            .offset(y: -radius)
                            .rotationEffect(.degrees(phase.endFraction * 360))
                    }
                }
            }

            VStack(spacing: 2) {
                Text(big)
                    .font(big.count <= 5 ? .vestelDisplay : .vestelH1)
                    .foregroundStyle(Color.fg1)
                Text(sub)
                    .font(.vestelCaption)
                    .foregroundStyle(Color.fg2)
            }
        }
        .frame(width: radius * 2 + 20, height: radius * 2 + 20)
    }

    private func clamp(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}

// MARK: - Egg Grid Component
// Egg indices: section 0 (A) = eggs 0,1 · section 1 (B) = eggs 2,3 · section 2 (C) = eggs 4,5

struct VEggGrid: View {
    @Binding var selected: Set<Int>
    var interactive: Bool = true
    var completedSections: Set<Int> = []

    let sections = ["A", "B", "C"]

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                ForEach(0..<3) { sectionIdx in
                    EggSlot(
                        topSelected: selected.contains(sectionIdx * 2),
                        bottomSelected: selected.contains(sectionIdx * 2 + 1),
                        isCompleted: completedSections.contains(sectionIdx),
                        interactive: interactive
                    ) { offset in
                        let eggIdx = sectionIdx * 2 + offset
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if selected.contains(eggIdx) { selected.remove(eggIdx) }
                            else { selected.insert(eggIdx) }
                        }
                    }
                }
            }
            HStack(spacing: 10) {
                ForEach(0..<3) { i in
                    Text(sections[i])
                        .font(.vestelCaption)
                        .foregroundStyle(completedSections.contains(i) ? Color.success : Color.fg3)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

private struct EggSlot: View {
    let topSelected: Bool
    let bottomSelected: Bool
    let isCompleted: Bool
    let interactive: Bool
    let onTap: (Int) -> Void

    private var sectionActive: Bool { topSelected || bottomSelected }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 6) {
                EggOval(isSelected: topSelected, isCompleted: isCompleted)
                    .onTapGesture { if interactive { onTap(0) } }
                EggOval(isSelected: bottomSelected, isCompleted: isCompleted)
                    .onTapGesture { if interactive { onTap(1) } }
            }
            .padding(8)
            .background(
                isCompleted ? Color.success.opacity(0.10) :
                sectionActive ? Color.bgSurface1 : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isCompleted ? Color.success :
                        sectionActive ? Color.accentOrange : Color.line1,
                        lineWidth: 1.5)
            )
            .frame(maxWidth: .infinity)

            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.success)
                    .background(Color.bgApp, in: Circle())
                    .offset(x: 4, y: -4)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isCompleted)
    }
}

private struct EggOval: View {
    let isSelected: Bool
    var isCompleted: Bool = false
    var body: some View {
        Circle()
            .fill(
                isCompleted   ? Color.success.opacity(0.20) :
                isSelected    ? Color.accentOrange.opacity(0.25) : Color.bgSurface2
            )
            .overlay(
                Circle()
                    .stroke(
                        isCompleted  ? Color.success.opacity(0.7) :
                        isSelected   ? Color.accentOrange : Color.bgSurface3,
                        lineWidth: 1.5)
            )
            .frame(width: 40, height: 40)
    }
}

// MARK: - Doneness Selector

struct VDonenessBulk: View {
    @Binding var active: String
    var caption: String = "All blocks · same level"
    let options = ["Soft", "Medium", "Hard"]

    var body: some View {
        VStack(spacing: 8) {
            Text(caption).font(.vestelCaption).foregroundStyle(Color.fg3)
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { opt in
                    Button {
                        withAnimation { active = opt }
                    } label: {
                        Text(opt)
                            .font(.vestelLabel)
                            .foregroundStyle(active == opt ? .white : Color.fg2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(active == opt ? Color.brandYellow : Color.bgSurface2)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

struct VDonenessSeparate: View {
    @Binding var levels: [String]
    var selectedEggs: Set<Int> = [0, 1, 2, 3, 4, 5]
    var completedSections: Set<Int> = []
    var caption: String = "Per block · own level"
    let sections = ["A", "B", "C"]
    let options = ["Soft", "Medium", "Hard"]

    private func sectionHasEgg(_ i: Int) -> Bool {
        selectedEggs.contains(i * 2) || selectedEggs.contains(i * 2 + 1)
    }

    var body: some View {
        let activeSections = (0..<3).filter { sectionHasEgg($0) }
        VStack(spacing: 8) {
            Text(caption).font(.vestelCaption).foregroundStyle(Color.fg3)
            HStack(spacing: 8) {
                ForEach(activeSections, id: \.self) { i in
                    let done = completedSections.contains(i)
                    Menu {
                        ForEach(options, id: \.self) { opt in
                            Button(opt) { levels[i] = opt }
                        }
                    } label: {
                        VStack(spacing: 4) {
                            HStack(spacing: 3) {
                                Text("Section \(sections[i])")
                                    .font(.vestelCaption)
                                    .foregroundStyle(done ? Color.success : Color.fg3)
                                if done {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(Color.success)
                                }
                            }
                            Text(levels[i].isEmpty ? "—" : levels[i])
                                .font(.vestelLabel)
                                .foregroundStyle(done ? Color.success : Color.fg1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(done ? Color.success.opacity(0.10) : Color.bgSurface1)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(done ? Color.success.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                    }
                    .animation(.easeInOut(duration: 0.25), value: done)
                }
            }
        }
    }
}

// MARK: - Settings Row

struct VListRow: View {
    let label: String
    var value: String? = nil
    var isToggle: Bool = false
    @Binding var toggleValue: Bool
    var showChev: Bool = true
    var onTap: (() -> Void)? = nil

    init(label: String, value: String? = nil, showChev: Bool = true, onTap: (() -> Void)? = nil) {
        self.label = label
        self.value = value
        self.isToggle = false
        self._toggleValue = .constant(false)
        self.showChev = showChev
        self.onTap = onTap
    }

    init(label: String, toggle: Binding<Bool>) {
        self.label = label
        self.value = nil
        self.isToggle = true
        self._toggleValue = toggle
        self.showChev = false
        self.onTap = nil
    }

    var body: some View {
        VStack(spacing: 0) {
            if isToggle {
                // Plain HStack — no Button wrapper so Toggle receives touch events directly
                HStack {
                    Text(label).font(.vestelBody).foregroundStyle(Color.fg1)
                    Spacer()
                    Toggle("", isOn: $toggleValue)
                        .tint(.brandYellow)
                        .labelsHidden()
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 2)
            } else {
                Button {
                    onTap?()
                } label: {
                    HStack {
                        Text(label).font(.vestelBody).foregroundStyle(Color.fg1)
                        Spacer()
                        if let v = value {
                            Text(v).font(.vestelBody).foregroundStyle(Color.fg2)
                        }
                        if showChev {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.fg3)
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 2)
                }
                .disabled(onTap == nil)
            }
            Divider().background(Color.line1)
        }
    }
}

// MARK: - Banner

struct VBanner: View {
    let message: String
    var detail: String? = nil
    var tone: BannerTone = .warning

    enum BannerTone { case success, warning, info }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(symbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(color)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(message).font(.vestelLabel).foregroundStyle(Color.fg1)
                if let d = detail {
                    Text(d).font(.vestelCaption).foregroundStyle(Color.fg3)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color.bgSurface1)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.4), lineWidth: 1)
        )
    }

    private var color: Color {
        switch tone { case .success: return .success; case .info: return .info; case .warning: return .warning }
    }
    private var symbol: String {
        switch tone { case .success: return "✓"; case .info: return "i"; case .warning: return "!" }
    }
}

// MARK: - Big Icon

struct VBigIcon: View {
    let systemName: String
    var tone: BannerTone = .primary

    enum BannerTone { case primary, success, warning }

    var body: some View {
        Circle()
            .fill(bgColor)
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(fgColor)
            )
    }

    private var bgColor: Color {
        switch tone { case .primary: return .brandYellowSoft; case .success: return Color(hex: "0D2E1E"); case .warning: return Color(hex: "2E2200") }
    }
    private var fgColor: Color {
        switch tone { case .primary: return .brandYellow; case .success: return .success; case .warning: return .warning }
    }
}

// MARK: - Onboarding Dots

struct VDots: View {
    let count: Int
    let active: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == active ? Color.brandYellow : Color.bgSurface3)
                    .frame(width: i == active ? 20 : 6, height: 6)
                    .animation(.easeInOut, value: active)
            }
        }
    }
}

// MARK: - Device Row

struct VDeviceRow: View {
    let name: String
    let subtitle: String
    let state: DeviceState

    enum DeviceState { case active, idle, offline }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.bgSurface2)
                    .frame(width: 42, height: 42)
                Image(systemName: "circle.hexagongrid.fill")
                    .foregroundStyle(Color.fg2)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.vestelBody).foregroundStyle(Color.fg1)
                Text(subtitle).font(.vestelCaption).foregroundStyle(Color.fg3)
            }
            Spacer()
            Text(stateLabel)
                .font(.vestelCaption)
                .foregroundStyle(stateColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(stateColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, 8)
    }

    private var stateLabel: String {
        switch state { case .active: return "Active"; case .idle: return "Idle"; case .offline: return "Offline" }
    }
    private var stateColor: Color {
        switch state { case .active: return .success; case .idle: return .fg3; case .offline: return .brandYellow }
    }
}

// MARK: - Preset Pill

struct VPresetPill: View {
    let title: String
    var isGhost: Bool = false
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.vestelLabel)
                .foregroundStyle(isGhost ? Color.fg3 : Color.fg1)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isGhost ? Color.clear : Color.bgSurface1)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isGhost ? Color.line2 : Color.line1, lineWidth: 1)
                )
        }
    }
}

// MARK: - Water Level Indicator

struct VWaterButton: View {
    @EnvironmentObject private var store: AppStore
    @State private var showDetail = false

    var body: some View {
        Button { showDetail = true } label: {
            ZStack {
                // Gauge body
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.bgSurface2)
                // Level fill — rises from the left edge like a ruler gauge
                RoundedRectangle(cornerRadius: 5)
                    .fill(waterColor)
                    .mask(alignment: .leading) {
                        GeometryReader { geo in
                            Rectangle().frame(width: geo.size.width * store.waterLevel)
                        }
                    }
                // Ruler tick marks
                HStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { i in
                        Rectangle()
                            .fill(Color.fg1.opacity(0.55))
                            .frame(width: 1.3)
                            .padding(.top, 3)
                            .padding(.bottom, i.isMultiple(of: 2) ? 8 : 4)
                        if i < 4 { Spacer(minLength: 0) }
                    }
                }
                .padding(.horizontal, 5)
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.fg1.opacity(0.55), lineWidth: 1.4)
            }
            .frame(width: 34, height: 22)
        }
        .sheet(isPresented: $showDetail) { WaterDetailSheet() }
    }

    private var waterColor: Color {
        if store.waterLevel < 0.15 { return .brandYellow }
        if store.waterLevel < 0.30 { return .warning }
        return .info
    }
}

private struct WaterDetailSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Water Tank", onBack: { dismiss() })

                Spacer()

                // Visual tank
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.line2, lineWidth: 2)
                        .frame(width: 90, height: 180)
                    RoundedRectangle(cornerRadius: 17)
                        .fill(waterColor.opacity(0.30))
                        .frame(width: 82, height: max(10, 168 * store.waterLevel))
                        .animation(.easeInOut(duration: 0.5), value: store.waterLevel)
                    Image(systemName: "drop.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(waterColor.opacity(0.7))
                        .padding(.bottom, 14)
                }

                Text("\(Int(store.waterLevel * 100))%")
                    .font(.vestelDisplay)
                    .foregroundStyle(Color.fg1)
                    .padding(.top, 28)

                Text(statusLabel)
                    .font(.vestelH3)
                    .foregroundStyle(waterColor)
                    .padding(.top, 6)

                Text(capacityHint)
                    .font(.vestelCaption)
                    .foregroundStyle(Color.fg3)
                    .padding(.top, 4)

                if store.waterLevel < 0.30 {
                    VBanner(
                        message: store.waterLevel < 0.15 ? "Refill now" : "Refill soon",
                        detail: cookWarning,
                        tone: .warning)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                }

                Spacer()

                VBtn(title: "Done") { dismiss() }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
    }

    private var waterColor: Color {
        if store.waterLevel < 0.15 { return .brandYellow }
        if store.waterLevel < 0.30 { return .warning }
        return .info
    }

    private var statusLabel: String {
        if store.waterLevel < 0.15 { return "Critical" }
        if store.waterLevel < 0.30 { return "Low" }
        if store.waterLevel < 0.60 { return "Moderate" }
        return "Good"
    }

    private var capacityHint: String {
        if store.waterLevel < 0.15 { return "Cannot complete most programs" }
        if store.waterLevel < 0.22 { return "Enough for Soft programs only" }
        if store.waterLevel < 0.33 { return "Enough for Soft & Medium programs" }
        return "Sufficient for all programs"
    }

    private var cookWarning: String {
        if store.waterLevel < 0.15 { return "Water level is too low to complete any cook program. Please refill." }
        if store.waterLevel < 0.22 { return "Only Soft (4 min) programs can be completed safely." }
        return "Hard (9 min) programs may not complete. Refill recommended."
    }
}
