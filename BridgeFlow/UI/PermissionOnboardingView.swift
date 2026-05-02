import AppKit
import BridgeFlowCore
import SwiftUI

struct PermissionOnboardingView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var permissions: PermissionManager
    @ObservedObject private var settings: SettingsStore
    @Binding private var isPresented: Bool

    @State private var currentStep: PermissionOnboardingStep = .accessibility
    @State private var didRequestLocalNetwork = false
    private let refreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
                                Text("macOS does not provide a preflight API for Local Network. BridgeFlow starts Bonjour discovery from this step; the system prompt may appear only if macOS has not already recorded a decision for this app.")
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
                                    refreshPermissionState(allowAutoAdvance: true)
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
        .onAppear {
            refreshPermissionState(allowAutoAdvance: true)
        }
        .onReceive(refreshTimer) { _ in
            refreshPermissionState(allowAutoAdvance: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshPermissionState(allowAutoAdvance: true)
        }
    }

    private var currentIndex: Int {
        PermissionOnboardingStep.allCases.firstIndex(of: currentStep) ?? 0
    }

    private var progress: PermissionOnboardingProgress {
        PermissionOnboardingProgress(
            snapshot: permissions.snapshot,
            localNetworkReady: localNetworkReady
        )
    }

    private var localNetworkReady: Bool {
        appState.peers.contains { peer in
            peer.status == .available || peer.status == .connected || peer.status == .active
        }
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
        refreshPermissionState(allowAutoAdvance: true)
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
        refreshPermissionState(allowAutoAdvance: false)
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
        progress.isComplete(step)
    }

    private func refreshPermissionState(allowAutoAdvance: Bool) {
        _ = appState.refreshPermissionsAndResumeInputCaptureIfPossible()
        guard allowAutoAdvance else {
            return
        }

        advanceWhenCurrentStepIsReady()
    }

    private func advanceWhenCurrentStepIsReady() {
        var step = currentStep
        var hops = 0
        while progress.isComplete(step),
              let next = progress.nextStep(afterCompleting: step),
              next != step,
              hops < PermissionOnboardingStep.allCases.count {
            step = next
            hops += 1
        }
        currentStep = step
    }

    private func statusText(for step: PermissionOnboardingStep) -> String {
        if progress.isComplete(step) {
            return "Ready"
        }
        if step == .localNetwork && didRequestLocalNetwork {
            return "Requested"
        }
        return "Needs action"
    }

    private func statusColour(for step: PermissionOnboardingStep) -> Color {
        if progress.isComplete(step) {
            return BridgeFlowPalette.success
        }
        if step == .localNetwork && didRequestLocalNetwork {
            return BridgeFlowPalette.cyan
        }
        return BridgeFlowPalette.warning
    }
}
