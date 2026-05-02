import BridgeFlowCore
import SwiftUI

struct LogsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var logger: BridgeLogger

    init(appState: AppState) {
        self.appState = appState
        _logger = ObservedObject(wrappedValue: appState.logger)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                IconHeader(title: "Logs", subtitle: "Recent connection and control events.")

                if logger.entries.isEmpty {
                    GlassCard {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                            Text("No events yet")
                            Spacer()
                        }
                        .foregroundStyle(BridgeFlowPalette.textSecondary)
                    }
                } else {
                    ForEach(logger.entries) { entry in
                        GlassCard {
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(colour(for: entry.level))
                                    .frame(width: 9, height: 9)
                                    .padding(.top, 6)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.message)
                                        .foregroundStyle(BridgeFlowPalette.textPrimary)
                                    Text(entry.date.formatted(date: .omitted, time: .standard))
                                        .font(.caption)
                                        .foregroundStyle(BridgeFlowPalette.textSecondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
    }

    private func colour(for level: AppLogEntry.Level) -> Color {
        switch level {
        case .info: BridgeFlowPalette.cyan
        case .warning: BridgeFlowPalette.warning
        case .error: BridgeFlowPalette.danger
        }
    }
}
