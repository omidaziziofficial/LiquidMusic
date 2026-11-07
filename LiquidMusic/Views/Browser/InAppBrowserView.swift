import SwiftUI
import WebKit

public struct InAppBrowserView: View {
    public let palette: LiquidPalette
    @Environment(\.dismiss) private var dismiss
    @State private var urlString: String = "https://www.google.com"
    @State private var inputURL: String = ""
    @State private var downloadProgress: String?
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Address Bar
                HStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(palette.secondary)
                        TextField("Search Google or enter web address...", text: $inputURL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onSubmit {
                                loadURL(inputURL)
                            }
                        if !inputURL.isEmpty {
                            Button {
                                inputURL = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(palette.tertiary)
                            }
                        }
                    }
                    .padding(8)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                if let progress = downloadProgress {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(palette.accent)
                        Text(progress)
                            .font(.subheadline)
                            .foregroundColor(palette.text)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(palette.accent.opacity(0.15))
                }
                
                // WebView
                WebViewWrapper(urlString: $urlString) { downloadURL in
                    handleAudioDownload(from: downloadURL)
                }
            }
            .navigationTitle("In-App Browser")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func loadURL(_ query: String) {
        var str = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.lowercased().hasPrefix("http://") || str.lowercased().hasPrefix("https://") {
            urlString = str
        } else if str.contains(".") && !str.contains(" ") {
            urlString = "https://" + str
        } else {
            let encoded = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            urlString = "https://www.google.com/search?q=\(encoded)"
        }
    }
    
    private func handleAudioDownload(from remoteURL: URL) {
        downloadProgress = "Downloading \(remoteURL.lastPathComponent)..."
        
        Task {
            do {
                let (tempFile, _) = try await URLSession.shared.download(from: remoteURL)
                let musicDir = await LibraryStore.shared.musicDirectoryURL
                let filename = remoteURL.lastPathComponent.isEmpty ? "downloaded_track.mp3" : remoteURL.lastPathComponent
                let destination = musicDir.appendingPathComponent(filename)
                
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.moveItem(at: tempFile, to: destination)
                
                await LibraryStore.shared.rescanLibrary()
                await MainActor.run {
                    downloadProgress = "Downloaded: \(filename)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        downloadProgress = nil
                    }
                }
            } catch {
                await MainActor.run {
                    downloadProgress = "Download failed."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        downloadProgress = nil
                    }
                }
            }
        }
    }
}

public struct WebViewWrapper: UIViewRepresentable {
    @Binding public var urlString: String
    public let onDownloadDetected: (URL) -> Void
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) {
        if let currentURL = uiView.url?.absoluteString, currentURL != urlString, let url = URL(string: urlString) {
            uiView.load(URLRequest(url: url))
        }
    }
    
    public class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewWrapper
        
        init(parent: WebViewWrapper) {
            self.parent = parent
        }
        
        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                let pathExt = url.pathExtension.lowercased()
                let audioExtensions = ["mp3", "m4a", "wav", "flac", "ogg", "aac"]
                if audioExtensions.contains(pathExt) {
                    parent.onDownloadDetected(url)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
}
