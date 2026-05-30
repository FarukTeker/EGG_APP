import SwiftUI

// MARK: - Design Tokens (Vestel-Wireframes-standalone-2.html)

extension Color {
    // Backgrounds
    static let bgApp      = Color(hex: "1B1B1D")
    static let bgSurface1 = Color(hex: "2A2A2C")
    static let bgSurface2 = Color(hex: "3A3A3D")
    static let bgSurface3 = Color(hex: "4A4A4D")

    // Text
    static let fg1        = Color.white
    static let fg2        = Color(hex: "B8B8BA")
    static let fg3        = Color(hex: "7A7A7C")
    static let fgDisabled = Color(hex: "5A5A5C")

    // Brand & accent
    static let brandRed      = Color(hex: "E72325")
    static let brandRedPress = Color(hex: "C61A1C")
    static let brandRedSoft  = Color(hex: "401012")
    static let accentOrange  = Color(hex: "F58025")

    // Semantic
    static let success = Color(hex: "2BB673")
    static let warning = Color(hex: "F5B400")
    static let info    = Color(hex: "4A8DFF")

    // Hairlines
    static let line1 = Color.white.opacity(0.08)
    static let line2 = Color.white.opacity(0.16)

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
        case .primary:      return .brandRed
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
        case .dangerOutline: return .brandRed
        }
    }

    private var borderColor: Color {
        switch kind {
        case .dangerOutline: return .brandRed
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
        .tint(.brandRed)
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
                        .background(active == opt ? Color.brandRed : Color.clear)
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
    var showAvatar: Bool = true
    var showBack: Bool = false
    var onBack: (() -> Void)? = nil

    var body: some View {
        HStack {
            if showBack {
                Button { onBack?() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.fg1)
                        .frame(width: 32, height: 32)
                }
            } else if showAvatar {
                Circle()
                    .fill(Color.bgSurface2)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.fg2)
                    )
            } else {
                Spacer().frame(width: 32)
            }
            Spacer()
            Image(systemName: "scale.3d")
                .foregroundStyle(Color.fg2)
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
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
                        .foregroundStyle(Color.brandRed)
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

// MARK: - Ring Timer Component

struct VRing: View {
    let big: String
    let sub: String
    var progress: Double = 0

    private let radius: CGFloat = 60
    private var circumference: CGFloat { 2 * .pi * radius }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.bgSurface2, lineWidth: 8)
                .frame(width: radius * 2, height: radius * 2)

            Circle()
                .trim(from: 0, to: progress / 100)
                .stroke(Color.accentOrange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))

            // Red dot at tip
            Circle()
                .fill(Color.brandRed)
                .frame(width: 8, height: 8)
                .offset(y: -radius)
                .rotationEffect(.degrees(-90 + progress / 100 * 360))

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
}

// MARK: - Egg Grid Component

struct VEggGrid: View {
    @Binding var selected: Set<Int>
    var interactive: Bool = true

    let sections = ["A", "B", "C"]

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                ForEach(0..<3) { i in
                    EggSlot(index: i, isSelected: selected.contains(i), interactive: interactive) {
                        if interactive {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if selected.contains(i) { selected.remove(i) }
                                else { selected.insert(i) }
                            }
                        }
                    }
                }
            }
            HStack(spacing: 10) {
                ForEach(0..<3) { i in
                    Text(sections[i])
                        .font(.vestelCaption)
                        .foregroundStyle(Color.fg3)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

private struct EggSlot: View {
    let index: Int
    let isSelected: Bool
    let interactive: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<2) { _ in
                Ellipse()
                    .fill(isSelected ? Color.accentOrange.opacity(0.25) : Color.bgSurface2)
                    .overlay(
                        Ellipse()
                            .stroke(isSelected ? Color.accentOrange : Color.bgSurface3, lineWidth: 1.5)
                    )
                    .frame(width: 36, height: 48)
            }
        }
        .padding(8)
        .background(isSelected ? Color.bgSurface1 : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentOrange : Color.line1, lineWidth: 1.5)
        )
        .frame(maxWidth: .infinity)
        .onTapGesture(perform: onTap)
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
                            .background(active == opt ? Color.brandRed : Color.bgSurface2)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

struct VDonenessSeparate: View {
    @Binding var levels: [String]
    var caption: String = "Per block · own level"
    let sections = ["A", "B", "C"]
    let options = ["Soft", "Medium", "Hard"]

    var body: some View {
        VStack(spacing: 8) {
            Text(caption).font(.vestelCaption).foregroundStyle(Color.fg3)
            HStack(spacing: 8) {
                ForEach(0..<3) { i in
                    Menu {
                        ForEach(options, id: \.self) { opt in
                            Button(opt) { levels[i] = opt }
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text("Section \(sections[i])").font(.vestelCaption).foregroundStyle(Color.fg3)
                            Text(levels[i].isEmpty ? "—" : levels[i])
                                .font(.vestelLabel)
                                .foregroundStyle(Color.fg1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.bgSurface1)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
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
        Button {
            onTap?()
        } label: {
            HStack {
                Text(label).font(.vestelBody).foregroundStyle(Color.fg1)
                Spacer()
                if isToggle {
                    Toggle("", isOn: $toggleValue)
                        .tint(.brandRed)
                        .labelsHidden()
                } else {
                    if let v = value {
                        Text(v).font(.vestelBody).foregroundStyle(Color.fg2)
                    }
                    if showChev {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.fg3)
                    }
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 2)
        }
        .disabled(isToggle || onTap == nil)
        Divider().background(Color.line1)
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
        switch tone { case .primary: return .brandRedSoft; case .success: return Color(hex: "0D2E1E"); case .warning: return Color(hex: "2E2200") }
    }
    private var fgColor: Color {
        switch tone { case .primary: return .brandRed; case .success: return .success; case .warning: return .warning }
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
                    .fill(i == active ? Color.brandRed : Color.bgSurface3)
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
        switch state { case .active: return .success; case .idle: return .fg3; case .offline: return .brandRed }
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
