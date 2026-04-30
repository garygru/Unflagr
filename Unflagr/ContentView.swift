import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var droppedFile: DroppedFile?
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            if let file = droppedFile {
                fileInfoView(file)
            } else {
                dropZoneView
            }
        }
        .frame(minWidth: 280, minHeight: 260)
        .background(Color(nsColor: .windowBackgroundColor))
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }

    private var dropZoneView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "flag.slash")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.orange)
            Text("Unflagr")
                .font(.title2.bold())
                .foregroundStyle(.primary)
            Text("Drop an app or file")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Browse…") { openPanel() }
                .buttonStyle(.bordered)
                .controlSize(.small)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1.5, dash: [6]),
                    antialiased: true
                )
                .foregroundStyle(isTargeted ? Color.orange : Color.white.opacity(0.12))
                .padding(12)
        }
        .background(isTargeted ? Color.orange.opacity(0.06) : .clear)
        .animation(.easeInOut(duration: 0.15), value: isTargeted)
    }

    private func fileInfoView(_ file: DroppedFile) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(nsImage: file.icon)
                    .resizable()
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text(file.displayName)
                        .font(.system(.subheadline, weight: .semibold))
                        .lineLimit(1)
                    Text(file.path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                Button {
                    droppedFile = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()
                .overlay(Color.white.opacity(0.08))

            if file.isLoading {
                Spacer()
                ProgressView()
                    .controlSize(.small)
                Spacer()
            } else if let error = file.errorMessage {
                Spacer()
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(8)
                    .multilineTextAlignment(.center)
                Spacer()
            } else if file.xattrs.isEmpty {
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.green)
                    Text("No extended attributes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                xattrListView(file)
            }

            if !file.xattrs.isEmpty {
                Divider()
                    .overlay(Color.white.opacity(0.08))
                HStack(spacing: 8) {
                    if file.hasQuarantine {
                        Button {
                            Task { await file.removeQuarantine() }
                        } label: {
                            Label("Remove Quarantine", systemImage: "flag.slash.fill")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .controlSize(.small)
                    }
                    if file.xattrs.count > 1 || !file.hasQuarantine {
                        Button {
                            Task { await removeAll(from: file) }
                        } label: {
                            Label("Remove All", systemImage: "trash.fill")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
    }

    private func xattrListView(_ file: DroppedFile) -> some View {
        ScrollView {
            VStack(spacing: 1) {
                ForEach(file.xattrs) { entry in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.name)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(entry.isQuarantine ? .orange : .primary)
                            Text(entry.displayValue)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button {
                            Task { await file.removeXattr(named: entry.name) }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red.opacity(0.8))
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.plain)
                        .help("Remove \(entry.name)")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(entry.isQuarantine ? Color.orange.opacity(0.1) : Color.white.opacity(0.03))
                    .cornerRadius(4)
                    .padding(.horizontal, 6)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func removeAll(from file: DroppedFile) async {
        for entry in file.xattrs {
            await file.removeXattr(named: entry.name)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url = url else { return }
            DispatchQueue.main.async { loadFile(url: url) }
        }
        return true
    }

    private func openPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.treatsFilePackagesAsDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            loadFile(url: url)
        }
    }

    private func loadFile(url: URL) {
        let file = DroppedFile(url: url)
        file.loadXattrs()
        droppedFile = file
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
