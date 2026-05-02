import BridgeFlowCore
import SwiftUI

struct PermissionOnboardingView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var permissions: PermissionManager
    @ObservedObject private var settings: SettingsStore
    @Binding private var isPresented: Bool

    @State private var currentStep: PermissionOnboardingStep = .accessibility
    @State private var didRequestLocalNetwork = false

    init(appState: AppState, isPresented: Binding<Bool>) {
        self.appState = appState
        _permissions = ObservedObject(wrappedValue: appState.permissions)
        _settings = ObservedObject(wrappedValue: appState.settings)
        _isPresented = isPresented
    }

    var body: some View {
        ZStack {
            BridgeFlowPalette.graphite.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 14) {
                    Image("BridgeFlowIcon", bundle: BridgeFlowResources.bundle)
                        .resizable()
                        .frame(width: 54, height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Set up BridgeFlow")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(BridgeFlowPalette.textPrimary)
                        Text("Grant the macOS permissions needed for reliable switching between Macs.")
                            .font(.callout)
                            .foregroundStyle(BridgeFlowPalette.textSecondary)
                    }
                }

                HStack(alignment: .top, spacing: 18) {
                    VStack(spacing: 10) {
                        ForEach(PermissionOnboardingStep.allCases) { step in
                            stepButton(step)
                        }
                    }
                    .frame(width: 220)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(BridgeFlowPalette.accentGradient.opacity(0.16))
                                    Image(systemName: currentStep.systemImage)
                                        .font(.title)
                                        .foregroundStyle(BridgeFlowPalette.cyan)
                                }
                                .frame(width: 60, height: 60)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(currentStep.title)
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(BridgeFlowPalette.textPrimary)
                                    Text(statusText(for: currentStep))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(statusColour(for: currentStep))
                                }
                            }

                            Text(currentStep.description)
                                .font(.body)
                                .foregroundStyle(BridgeFlowPalette.textSecondary)

                            if currentStep == .localNetwork {
                                Text("macOS does not provide a preflight API for Local Network. BridgeFlow starts Bonjour discovery from this step so the system prompt appears while setup is visible.")
                                    .font(.callout)
                                    .foregroundStyle(BridgeFlowPalette.textSecondary)
                            }

                            Spacer(minLength: 0)

                            HStack(spacing: 10) {
                                GradientButton(title: currentStep.primaryActionTitle, systemImage: currentStep.systemImage) {
                                    performPrimaryAction()
                                }

                                if currentStep != .localNetwork {
                                    Button {
                                        openSettingsForCurrentStep()
                                    } label: {
                                        Label("Open System Settings", systemImage: "gear")
                                    }
                                }

                                Button {
                                    _ = permissions.refresh()
                                } label: {
                                    Label("Refresh", systemImage: "arrow.clockwise")
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    }
                }

                HStack {
                    Button("Continue without all permissions") {
                        complete(startBridgeFlow: false)
                    }

                    Spacer()

                    Button("Back") {
                        move(offset: -1)
                    }
                    .disabled(currentIndex == 0)

                    Button(currentIndex == PermissionOnboardingStep.allCases.count - 1 ? "Finish & Start" : "Continue") {
                        if currentIndex == PermissionOnboardingStep.allCases.count - 1 {
                            complete(startBridgeFlow: true)
                        } else {
                            move(offset: 1)
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(26)
        }
        .preferredColorScheme(.dark)
    }

    private var currentIndex: Int {
        PermissionOnboardingStep.allCases.firstIndex(of: currentStep) ?? 0
    }

    private func stepButton(_ step: PermissionOnboardingStep) -> some View {
        Button {
            currentStep = step
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isComplete(step) ? "checkmark.circle.fill" : step.systemImage)
                    .foregroundStyle(isComplete(step) ? BridgeFlowPalette.success : BridgeFlowPalette.textSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(step.title)
                        .font(.headline)
                    Text(statusText(for: step))
                        .font(.caption)
                        .foregroundStyle(statusColour(for: step))
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(step == currentStep ? BridgeFlowPalette.panelElevated : BridgeFlowPalette.panel.opacity(0.64))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(step == currentStep ? BridgeFlowPalette.cyan.opacity(0.35) : .white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(BridgeFlowPalette.textPrimary)
    }

    private func performPrimaryAction() {
        switch currentStep {
        case .accessibility:
            permissions.requestAccessibility()
        case .inputMonitoring:
            _ = permissions.requestInputMonitoring()
        case .localNetwork:
            didRequestLocalNetwork = true
            appState.requestLocalNetworkAccess()
        }
    }

    private func openSettingsForCurrentStep() {
        switch currentStep {
        case .accessibility:
            permissions.openAccessibilitySettings()
        case .inputMonitoring:
            permissions.openInputMonitoringSettings()
        case .localNetwork:
            permissions.openLocalNetworkSettings()
        }
    }

    private func move(offset: Int) {
        let steps = PermissionOnboardingStep.allCases
        let nextIndex = min(max(currentIndex + offset, 0), steps.count - 1)
        currentStep = steps[nextIndex]
    }

    private func complete(startBridgeFlow: Bool) {
        settings.permissionsOnboardingCompleted = true
        appState.requestLocalNetworkAccess()
        _ = permissions.refresh()
        if startBridgeFlow {
            appState.start()
        }
        isPresented = false
    }

    private func isComplete(_ step: PermissionOnboardingStep) -> Bool {
        switch step {
        case .accessibility:
            permissions.snapshot.accessibilityGranted
        case .inputMonitoring:
            permissions.snapshot.inputMonitoringGranted
        case .localNetwork:
            didRequestLocalNetwork || appState.connectionStatus != .stopped || !appState.peers.isEmpty
        }
    }

    private func statusText(for step: PermissionOnboardingStep) -> String {
        isComplete(step) ? "Ready" : "Needs action"
    }

    private func statusColour(for step: PermissionOnboardingStep) -> Color {
        isComplete(step) ? BridgeFlowPalette.success : BridgeFlowPalette.warning
    }
}
