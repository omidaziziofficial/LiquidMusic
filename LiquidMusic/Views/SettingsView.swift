import SwiftUI

public struct SettingsView: View {
    @ObservedObject var store = LibraryStore.shared
    @ObservedObject var player = AudioPlayerService.shared
    public let palette: LiquidPalette
    
    @State private var showSleepTimerSheet: Bool = false
    @State private var showInAppBrowser: Bool = false
    @State private var showIconPicker: Bool = false
    
    public var body: some View {
        NavigationStack {
            ZStack {
                palette.background.ignoresSafeArea()
                
                Form {
                    // MARK: - Appearance
                    Section(header: Text("Appearance")) {
                        // Theme Mode
                        Picker("Theme", selection: Binding(
                            get: { store.settings.themeMode },
                            set: { newMode in
                                store.updateSettings { $0.themeMode = newMode }
                            }
                        )) {
                            ForEach(ThemeMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 4)
                        
                        // Accent Color Swatches
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Accent Color")
                                .font(.subheadline)
                                .foregroundColor(palette.text)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(0..<LiquidTheme.accentColors.count, id: \.self) { idx in
                                        let col = LiquidTheme.accentColors[idx]
                                        let isSelected = store.settings.accent == idx
                                        
                                        Circle()
                                            .fill(col)
                                            .frame(width: 34, height: 34)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(Color.white, lineWidth: isSelected ? 3 : 0)
                                            )
                                            .shadow(color: col.opacity(0.4), radius: isSelected ? 6 : 2)
                                            .scaleEffect(isSelected ? 1.15 : 1.0)
                                            .onTapGesture {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    store.updateSettings { $0.accent = idx }
                                                }
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            }
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        
                        // Reduce Transparency
                        Toggle("Reduce Transparency", isOn: Binding(
                            get: { store.settings.reduceTransparency },
                            set: { val in store.updateSettings { $0.reduceTransparency = val } }
                        ))
                        
                        // Artwork Background
                        Toggle("Artwork Background", isOn: Binding(
                            get: { store.settings.artworkBackground },
                            set: { val in store.updateSettings { $0.artworkBackground = val } }
                        ))
                        
                        // App Icon
                        Button {
                            showIconPicker = true
                        } label: {
                            HStack {
                                Text("App Icon")
                                    .foregroundColor(palette.text)
                                Spacer()
                                Text(AppIconOption.allIcons[min(store.settings.appIcon, AppIconOption.allIcons.count - 1)].name)
                                    .foregroundColor(palette.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(palette.tertiary)
                            }
                        }
                    }
                    
                    // MARK: - Playback
                    Section(header: Text("Playback")) {
                        Toggle("Crossfade", isOn: Binding(
                            get: { store.settings.crossfade },
                            set: { val in store.updateSettings { $0.crossfade = val } }
                        ))
                        
                        if store.settings.crossfade {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Crossfade Length")
                                    Spacer()
                                    Text("\(store.settings.crossfadeSec) seconds")
                                        .foregroundColor(palette.secondary)
                                }
                                Slider(
                                    value: Binding(
                                        get: { Double(store.settings.crossfadeSec) },
                                        set: { val in store.updateSettings { $0.crossfadeSec = Int(val) } }
                                    ),
                                    in: 3...20,
                                    step: 1
                                )
                                .tint(palette.accent)
                            }
                            
                            Toggle("Mix When Changing Song", isOn: Binding(
                                get: { store.settings.crossfadeManual },
                                set: { val in store.updateSettings { $0.crossfadeManual = val } }
                            ))
                        }
                        
                        Toggle("Swipe Cover to Change Song", isOn: Binding(
                            get: { store.settings.swipeCover },
                            set: { val in store.updateSettings { $0.swipeCover = val } }
                        ))
                        
                        Toggle("Previous Restarts the Song First", isOn: Binding(
                            get: { store.settings.restartOnPrevious },
                            set: { val in store.updateSettings { $0.restartOnPrevious = val } }
                        ))
                        
                        // Sleep Timer Row
                        Button {
                            showSleepTimerSheet = true
                        } label: {
                            HStack {
                                Text("Sleep Timer")
                                    .foregroundColor(palette.text)
                                Spacer()
                                if player.sleepTimerActive {
                                    let mins = player.sleepTimerRemainingSeconds / 60
                                    let secs = player.sleepTimerRemainingSeconds % 60
                                    Text(String(format: "%d:%02d", mins, secs))
                                        .foregroundColor(palette.accent)
                                        .fontWeight(.semibold)
                                } else {
                                    Text("Off")
                                        .foregroundColor(palette.secondary)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(palette.tertiary)
                            }
                        }
                        
                        Toggle("Fade Out on Sleep Timer", isOn: Binding(
                            get: { store.settings.fadeOnSleep },
                            set: { val in store.updateSettings { $0.fadeOnSleep = val } }
                        ))
                    }
                    
                    // MARK: - Library & Content
                    Section(header: Text("Library")) {
                        Toggle("Find Lyrics Automatically", isOn: Binding(
                            get: { store.settings.autoLyrics },
                            set: { val in store.updateSettings { $0.autoLyrics = val } }
                        ))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Ignore Short Audio")
                                Spacer()
                                Text("Under \(store.settings.minDurationSec) seconds")
                                    .foregroundColor(palette.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: { Double(store.settings.minDurationSec) },
                                    set: { val in store.updateSettings { $0.minDurationSec = Int(val) } }
                                ),
                                in: 0...60,
                                step: 5
                            )
                            .tint(palette.accent)
                        }
                        
                        Button {
                            Task {
                                await store.rescanLibrary()
                            }
                        } label: {
                            HStack {
                                Text("Rescan Library")
                                    .foregroundColor(palette.accent)
                                Spacer()
                                if store.isScanning {
                                    ProgressView().tint(palette.accent)
                                }
                            }
                        }
                    }
                    
                    // MARK: - Voice Control (Jarvis)
                    Section(header: Text("Voice Control (Offline)")) {
                        Toggle("Voice Control", isOn: Binding(
                            get: { store.settings.voiceControl },
                            set: { val in
                                store.updateSettings { $0.voiceControl = val }
                                VoiceAssistantService.shared.startListeningIfEnabled()
                            }
                        ))
                        
                        if store.settings.voiceControl {
                            Toggle("Use Headset Mic When Paused", isOn: Binding(
                                get: { store.settings.voiceBluetoothMic },
                                set: { val in store.updateSettings { $0.voiceBluetoothMic = val } }
                            ))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Offline Assistant: Jarvis")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(palette.text)
                                Text("Say \"Jarvis\" or \"Hey Jarvis\" followed by: Play Music, Pause Music, Next Music, Previous Music, Repeat Music, Open Songs, Open Artist, Open Album, Open Search, Open Favorites, Add Favorites, Turn On Dark Mode, etc.")
                                    .font(.caption)
                                    .foregroundColor(palette.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // MARK: - In-App Browser
                    Section(header: Text("In-App Tools")) {
                        Button {
                            showInAppBrowser = true
                        } label: {
                            HStack {
                                Label("In-App Web Browser", systemImage: "globe")
                                    .foregroundColor(palette.text)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(palette.tertiary)
                            }
                        }
                    }
                    
                    // MARK: - About
                    Section(header: Text("About")) {
                        HStack {
                            Text("App Name")
                            Spacer()
                            Text("Liquid Music")
                                .foregroundColor(palette.secondary)
                        }
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("3.8")
                                .foregroundColor(palette.secondary)
                        }
                        HStack {
                            Text("Designed & Developed by")
                            Spacer()
                            Text("Omid Azizi")
                                .fontWeight(.medium)
                                .foregroundColor(palette.accent)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .padding(.bottom, 140)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showSleepTimerSheet) {
                SleepTimerSheet(palette: palette)
            }
            .sheet(isPresented: $showInAppBrowser) {
                InAppBrowserView(palette: palette)
            }
            .sheet(isPresented: $showIconPicker) {
                AppIconPickerSheet(palette: palette)
            }
        }
    }
}

// MARK: - App Icon Picker Sheet
public struct AppIconPickerSheet: View {
    public let palette: LiquidPalette
    @ObservedObject var store = LibraryStore.shared
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        NavigationStack {
            List(AppIconOption.allIcons) { iconOption in
                Button {
                    store.updateSettings { $0.appIcon = iconOption.id }
                    // Update iOS Alternate App Icon
                    if UIApplication.shared.supportsAlternateIcons {
                        UIApplication.shared.setAlternateIconName(iconOption.iconName)
                    }
                    dismiss()
                } label: {
                    HStack(spacing: 16) {
                        Image(iconOption.previewAsset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        
                        Text(iconOption.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(palette.text)
                        
                        Spacer()
                        
                        if store.settings.appIcon == iconOption.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(palette.accent)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("App Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
