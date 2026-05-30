import SwiftUI

// MARK: - UC-15: Devices Management

struct DevicesTabView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showPairing = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgApp.ignoresSafeArea()
                if store.devices.isEmpty {
                    EmptyDevicesView()
                } else {
                    deviceList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Devices").font(.vestelH3).foregroundStyle(Color.fg1)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPairing = true
                    } label: {
                        Image(systemName: "plus").foregroundStyle(Color.brandRed)
                    }
                }
            }
            .sheet(isPresented: $showPairing) {
                PairingFlowView(onComplete: { showPairing = false },
                                onCancel:  { showPairing = false })
            }
        }
    }

    private var deviceList: some View {
        List {
            ForEach(store.devices) { device in
                Button {
                    store.setActiveDevice(device)
                } label: {
                    HStack {
                        VDeviceRow(
                            name: device.name,
                            subtitle: "\(device.modelCode) · \(device.state.displayText)",
                            state: device.state.viewState
                        )
                        if store.activeDevice?.id == device.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.brandRed)
                        }
                    }
                }
                .listRowBackground(Color.bgSurface1)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparatorTint(Color.line1)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Empty Devices View (UC-21 error state)

struct EmptyDevicesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showPairing = false
    @State private var demoMode = false

    var body: some View {
        VStack(spacing: 0) {
            VTopbar()
            Spacer()
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 56)).foregroundStyle(Color.fg3)
            Text("No cooker connected")
                .font(.vestelH3).foregroundStyle(Color.fg1).padding(.top, 16)
            Text("Pair your Vestel Smart Egg Cooker to start cooking from your phone.")
                .font(.vestelCaption).foregroundStyle(Color.fg2)
                .multilineTextAlignment(.center).padding(.horizontal, 40).padding(.top, 10)
            Spacer()
            VStack(spacing: 12) {
                VBtn(title: "Pair a device") { showPairing = true }
                VBtn(title: "Browse demo mode", kind: .ghost) {
                    let demo = EggDevice(name: "Demo Cooker", modelCode: "VS-DEMO", state: .active)
                    store.pairDevice(demo)
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 40)
        }
        .background(Color.bgApp.ignoresSafeArea())
        .sheet(isPresented: $showPairing) {
            PairingFlowView(onComplete: { showPairing = false },
                            onCancel:  { showPairing = false })
        }
    }
}

// MARK: - Helpers

private extension DeviceConnectionState {
    var viewState: VDeviceRow.DeviceState {
        switch self { case .active: return .active; case .idle: return .idle; case .offline: return .offline }
    }
    var displayText: String {
        switch self { case .active: return "Online"; case .idle: return "Idle"; case .offline: return "Offline" }
    }
}
