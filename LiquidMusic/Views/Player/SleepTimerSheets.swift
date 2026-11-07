import SwiftUI

public struct SleepTimerSheet: View {
    public let palette: LiquidPalette
    @ObservedObject var player = AudioPlayerService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCustomSheet: Bool = false
    
    public var body: some View {
        NavigationStack {
            List {
                if player.sleepTimerActive {
                    Section {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Timer Active")
                                    .fontWeight(.bold)
                                    .foregroundColor(palette.accent)
                                let mins = player.sleepTimerRemainingSeconds / 60
                                let secs = player.sleepTimerRemainingSeconds % 60
                                Text(String(format: "%d:%02d remaining", mins, secs))
                                    .font(.subheadline)
                                    .foregroundColor(palette.secondary)
                            }
                            Spacer()
                            Button("+15 min") {
                                player.extendSleepTimer(minutes: 15)
                            }
                            .buttonStyle(.bordered)
                            .tint(palette.accent)
                        }
                        
                        Button(role: .destructive) {
                            player.cancelSleepTimer()
                            dismiss()
                        } label: {
                            Text("Turn Off Timer")
                        }
                    }
                }
                
                Section {
                    Button("15 minutes") {
                        player.startSleepTimer(mode: .minutes(15))
                        dismiss()
                    }
                    Button("30 minutes") {
                        player.startSleepTimer(mode: .minutes(30))
                        dismiss()
                    }
                    Button("45 minutes") {
                        player.startSleepTimer(mode: .minutes(45))
                        dismiss()
                    }
                    Button("1 hour") {
                        player.startSleepTimer(mode: .minutes(60))
                        dismiss()
                    }
                    Button("End of Current Song") {
                        player.startSleepTimer(mode: .endOfTrack)
                        dismiss()
                    }
                    Button("Custom...") {
                        showCustomSheet = true
                    }
                }
            }
            .navigationTitle("Sleep Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showCustomSheet) {
                SleepCustomSheet(palette: palette)
            }
        }
    }
}

public struct SleepCustomSheet: View {
    public let palette: LiquidPalette
    @ObservedObject var player = AudioPlayerService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var customMinutes: Int = 20
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Stop after")) {
                    Stepper("\(customMinutes) minutes", value: $customMinutes, in: 1...300, step: 5)
                }
            }
            .navigationTitle("Custom Sleep Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        player.startSleepTimer(mode: .minutes(customMinutes))
                        dismiss()
                    }
                    .foregroundColor(palette.accent)
                }
            }
        }
    }
}
