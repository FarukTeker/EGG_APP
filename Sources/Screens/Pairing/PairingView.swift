import SwiftUI

// MARK: - UC-05: Device Pairing Flow

struct PairingFlowView: View {
    @EnvironmentObject private var store: AppStore
    @State private var route: PairingRoute = .qr
    @State private var selectedDevice: EggDevice? = nil
    var onComplete: () -> Void
    var onCancel: () -> Void

    enum PairingRoute { case qr, searching, found, success, failed }

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            switch route {
            case .qr:       QRScanView(onSearch: { route = .searching }, onCancel: onCancel)
            case .searching: PairingSearchView(onFound: { route = .found }, onCancel: onCancel)
            case .found:    PairingFoundView(onConnect: { d in selectedDevice = d; route = .success },
                                             onRetry: { route = .searching },
                                             onFailed: { route = .failed })
            case .success:  PairingSuccessView(device: selectedDevice, onStart: {
                                if let d = selectedDevice { store.pairDevice(d) }
                                onComplete()
                            }, onPairAnother: { route = .qr })
            case .failed:   PairingFailedView(onRetry: { route = .searching }, onHelp: { })
            }
        }
    }
}

// MARK: - QR Scan (UC-05 step 1)

struct QRScanView: View {
    var onSearch: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VNavHeader(title: "Add device", onBack: onCancel)
            Spacer()

            // QR placeholder
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.brandRed, lineWidth: 2)
                .frame(width: 180, height: 180)
                .overlay(
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.fg2)
                )

            Text("Scan the QR on the device")
                .font(.vestelCaption)
                .foregroundStyle(Color.fg2)
                .padding(.top, 16)

            Spacer()

            VBtn(title: "Enter code manually", kind: .ghost) { onSearch() }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { onSearch() }
        }
    }
}

// MARK: - Pairing Searching (UC-05 step 2)

struct PairingSearchView: View {
    var onFound: () -> Void
    var onCancel: () -> Void
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            VTopbar()
            Spacer()

            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.accentOrange.opacity(0.3 - Double(i) * 0.08), lineWidth: 2)
                        .frame(width: CGFloat(60 + i * 30), height: CGFloat(60 + i * 30))
                        .scaleEffect(pulseScale)
                        .animation(.easeInOut(duration: 1.2).repeatForever().delay(Double(i) * 0.3), value: pulseScale)
                }
                Circle()
                    .fill(Color.accentOrange)
                    .frame(width: 20, height: 20)
            }
            .frame(width: 140, height: 140)
            .onAppear { pulseScale = 1.15 }

            Text("Looking for your cooker…")
                .font(.vestelH2)
                .foregroundStyle(Color.fg1)
                .multilineTextAlignment(.center)
                .padding(.top, 24)

            Text("Keep the device powered on and within 5 meters.")
                .font(.vestelCaption)
                .foregroundStyle(Color.fg2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 8)

            Spacer()

            VBtn(title: "Cancel", kind: .ghost) { onCancel() }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { onFound() }
        }
    }
}

// MARK: - Pairing Found (UC-05 step 3)

struct PairingFoundView: View {
    var onConnect: (EggDevice) -> Void
    var onRetry: () -> Void
    var onFailed: () -> Void

    let foundDevices: [EggDevice] = [
        EggDevice(name: "EggMaster Pro", modelCode: "VS-EG-2025", state: .active),
        EggDevice(name: "EggMaster Pro", modelCode: "VS-EG-2024", state: .idle)
    ]

    @State private var selectedIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VTopbar()
            Text("Choose your device")
                .font(.vestelH3)
                .foregroundStyle(Color.fg1)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)

            ForEach(Array(foundDevices.enumerated()), id: \.element.id) { i, device in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.bgSurface2)
                        .frame(width: 42, height: 42)
                        .overlay(Image(systemName: "circle.hexagongrid.fill").foregroundStyle(Color.fg2))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.name).font(.vestelBody).foregroundStyle(Color.fg1)
                        Text("\(device.modelCode) · \(i == 0 ? "2m" : "4m") away")
                            .font(.vestelCaption).foregroundStyle(Color.fg3)
                    }
                    Spacer()
                    Text("Found")
                        .font(.vestelCaption)
                        .foregroundStyle(Color.success)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.success.opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                .background(selectedIndex == i ? Color.bgSurface1 : Color.clear)
                .contentShape(Rectangle())
                .onTapGesture { selectedIndex = i }

                Divider().background(Color.line1).padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 12) {
                VBtn(title: "Connect") {
                    onConnect(EggDevice(name: foundDevices[selectedIndex].name,
                                        modelCode: foundDevices[selectedIndex].modelCode,
                                        state: .active))
                }
                VBtn(title: "Scan again", kind: .ghost) { onRetry() }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Pairing Success (UC-05 step 4)

struct PairingSuccessView: View {
    let device: EggDevice?
    var onStart: () -> Void
    var onPairAnother: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VTopbar(showAvatar: false)
            Spacer()

            VBigIcon(systemName: "checkmark", tone: .success)
            Text("You're connected!")
                .font(.vestelH2)
                .foregroundStyle(Color.fg1)
                .padding(.top, 16)
            Text("EggMaster Pro is ready to go. Let's set up your first cook.")
                .font(.vestelCaption)
                .foregroundStyle(Color.fg2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 10)

            if let d = device {
                VDeviceRow(name: d.name, subtitle: "\(d.modelCode)", state: .active)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
            }

            Spacer()

            VStack(spacing: 12) {
                VBtn(title: "Start cooking") { onStart() }
                VBtn(title: "Pair another", kind: .ghost) { onPairAnother() }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.bgApp.ignoresSafeArea())
    }
}

// MARK: - Pairing Failed (UC-05 alt flow)

struct PairingFailedView: View {
    var onRetry: () -> Void
    var onHelp: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VTopbar(showAvatar: false)
            Spacer()

            VBigIcon(systemName: "xmark", tone: .primary)
            Text("Couldn't connect")
                .font(.vestelH2)
                .foregroundStyle(Color.fg1)
                .padding(.top, 16)
            Text("Make sure your cooker is powered on, in pairing mode, and on the same Wi-Fi network.")
                .font(.vestelCaption)
                .foregroundStyle(Color.fg2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 10)

            VStack(spacing: 10) {
                VBanner(message: "Check Wi-Fi connection", tone: .warning)
                VBanner(message: "Hold the device button for 5s", tone: .info)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer()

            VStack(spacing: 12) {
                VBtn(title: "Try again") { onRetry() }
                VBtn(title: "Get help", kind: .ghost) { onHelp() }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.bgApp.ignoresSafeArea())
    }
}
