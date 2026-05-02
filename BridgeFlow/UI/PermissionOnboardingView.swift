import AppKit
import BridgeFlowCore
import SwiftUI

struct PermissionOnboardingView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var permissions: PermissionManager
    @ObservedObject private var settings: SettingsStore

    @State private var currentStep: PermissionOnboardingStep = .accessibility
    @State private var requestedSteps: Set<PermissionOnboardingStep> = []
    @State private var didRequestLocalNetwork = false

    private let refreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(appState: AppState) {
        self.appState = appState
        _permissions = ObservedObject(wrappedValue: appState.permissions)
        _settings = ObservedObject(wrappedValue: appState.settings)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                HStack(alignment: .top, spacing: 20) {
                    stepList
                        .frame(width: 250)

                    setupPanel
                        .frame(maxWidth: .infinity, minHeight: 390)
                }

                footer
            }
            .padding(28)
        }
        .onAppear {
            refreshPermissionState(allowAutoAdvance: true)
            requestCurrentStepIfNeeded()
        }
        .onChange(of: currentStep) { _ in
            requestCurrentStepIfNeeded()
        }
        .onReceive(refreshTimer) { _ in
            refreshPermissionState(allowAutoAdvance: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshPermissionState(allowAutoAdvance: true)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image("BridgeFlowIcon", bundle: BridgeFlowResources.bundle)
                .resizable()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Setup")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(BridgeFlowPalette.textPrimary)
                Text("BridgeFlow needs these macOS approvals before edge switching can work reliably.")
                    .font(.callout)
                    .foregroundStyle(BridgeFlowPalette.textSecondary)
            }

            Spacer()
        }
    }

    private var stepList: some View {
        VStack(spacing: 10) {
            ForEach(PermissionOnboardingStep.allCases) { step in
                Button {
                    currentStep = step
                } label: {
                    HStack(spacing: 11) {
                        Image(systemName: icon(for: step))
                            .font(.headline)
                            .foregroundStyle(colour(for: step))
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(step.title)
                                .font(.headline)
                                .foregroundStyle(BridgeFlowPalette.textPrimary)
                            Text(statusText(for: step))
                                .font(.caption)
                                .foregroundStyle(colour(for: step))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(step == currentStep ? BridgeFlowPalette.panelElevated : BridgeFlowPalette.panel.opacity(0.68))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(step == currentStep ? BridgeFlowPalette.cyan.opacity(0.42) : .white.opacity(0.06), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var setupPanel: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(colour(for: currentStep).opacity(0.16))
                        Image(systemName: currentStep.systemImage)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(colour(for: currentStep))
                    }
                    .frame(width: 58, height: 58)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentStep.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(BridgeFlowPalette.textPrimary)
                        Text(statusText(for: currentStep))
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(colour(for: currentStep))
                    }

                    Spacer()
                }

                Text(currentStep.description)
                    .font(.body)
                    .foregroundStyle(BridgeFlowPalette.textSecondary)

                setupNotes

                Spacer(minLength: 0)

                actionRow
            }
        }
    }

    @ViewBuilder
    private var setupNotes: some View {
        if currentStep == .localNetwork {
            Text("Apple does not provide a direct Local Network request or preflight API. BridgeFlow starts Bonjour discovery here; a native prompt appears only when macOS needs a decision for this signed app. If the prompt was already answered, use System Settings > Privacy & Security > Local Network.")
                .font(.callout)
                .foregroundStyle(BridgeFlowPalette.textSecondary)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(BridgeFlowPalette.panel.opacity(0.72))
                )
        } else if isComplete(currentStep) {
            Text("Ready. BridgeFlow will move to the next setup item automatically.")
                .font(.callout)
                .foregroundStyle(BridgeFlowPalette.success)
        } else {
            Text("If macOS opens System Settings, enable BridgeFlow there and return to this window. This screen refreshes automatically.")
                .font(.callout)
                .foregroundStyle(BridgeFlowPalette.textSecondary)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                performPrimaryAction(force: true)
            } label: {
                Label(currentStep.primaryActionTitle, systemImage: currentStep.systemImage)
                    .frame(minWidth: 164)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(BridgeFlowPalette.blue)

            Button {
                openSettingsForCurrentStep()
            } label: {
                Label("System Settings", systemImage: "gear")
                    .frame(minWidth: 148)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button {
                refreshPermissionState(allowAutoAdvance: true)
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .frame(minWidth: 104)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private var footer: some View {
        HStack {
            Text("Setup state updates live. Local Network is confirmed by peer discovery because macOS does not expose a permission status API.")
                .font(.caption)
                .foregroundStyle(BridgeFlowPalette.textSecondary)

            Spacer()

            Button {
                settings.permissionsOnboardingCompleted = true
                appState.requestLocalNetworkAccess()
                if settings.startOnLaunch {
                    appState.start()
                }
            } label: {
                Label("Finish Setup", systemImage: "checkmark")
                    .frame(minWidth: 132)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(canFinish ? BridgeFlowPalette.success : BridgeFlowPalette.textSecondary)
            .disabled(!canFinish)
        }
    }

    private var canFinish: Bool {
        permissions.snapshot.accessibilityGranted && permissions.snapshot.inputMonitoringGranted
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

    private func performPrimaryAction(force: Bool) {
        if !force, requestedSteps.contains(currentStep) {
            return
        }
        requestedSteps.insert(currentStep)

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

    private func requestCurrentStepIfNeeded() {
        guard !isComplete(currentStep) else {
            return
        }
        performPrimaryAction(force: false)
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

    private func isComplete(_ step: PermissionOnboardingStep) -> Bool {
        progress.isComplete(step)
    }

    private func icon(for step: PermissionOnboardingStep) -> String {
        isComplete(step) ? "checkmark.circle.fill" : step.systemImage
    }

    private func statusText(for step: PermissionOnboardingStep) -> String {
        if progress.isComplete(step) {
            return "Ready"
        }
        if step == .localNetwork && didRequestLocalNetwork {
            return step.pendingStatusText
        }
        return step.pendingStatusText
    }

    private func colour(for step: PermissionOnboardingStep) -> Color {
        if progress.isComplete(step) {
            return BridgeFlowPalette.success
        }
        if step == .localNetwork && didRequestLocalNetwork {
            return BridgeFlowPalette.cyan
        }
        return BridgeFlowPalette.warning
    }
}
