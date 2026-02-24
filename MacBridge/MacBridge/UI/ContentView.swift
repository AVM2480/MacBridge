import SwiftUI

struct PixelFile: Hashable {
    let rawName: String
    let isDirectory: Bool

    // Removes the trailing slash from folders so it looks clean inside the UI directory
    var cleanName: String {
        return isDirectory ? String(rawName.dropLast()) : rawName
        }
    }


struct ContentView: View {
    // State variables for managing data and UI updates
    @State private var files: [PixelFile] = []
    @State private var status = "Connected"
    @State private var selectedFiles = Set<PixelFile>()
    @State private var searchText = ""
    @State private var currentPath = "/sdcard/Download"
    @State private var forwardHistory: [String] = [] // Forward state saved
    
    // Naming and Progress States
    @State private var customFolderName = "_Pixel_Export"
    @State private var downloadProgress: Double = 0.0
    @State private var isDownloading = false
    @State private var showFAQ = false
    
    let watcher = PixelWatcher()
    
    // Computed property to automatically organize folders by date
    var folderWithDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        return "\(dateString)\(customFolderName)"
    }
    
    var filteredFiles: [PixelFile] {
        if searchText.isEmpty {
            return files
        } else {
            return files.filter { file in
                file.cleanName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func refreshCurrentPath() {
        selectedFiles.removeAll()
        status = "Loading..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            watcher.listFiles(at: currentPath) { fetchedFiles in
                DispatchQueue.main.async {
                    self.files = fetchedFiles
                    self.status = "Connected"
                }
            }
        }
    }
    
    func colorForFile(file: PixelFile) -> Color {
        // 1. Check if file is a folder
        if file.isDirectory {
            return Color(red: 218 / 255.0, green: 179 / 255.0, blue: 136 / 255.0, opacity: 1.0)
        }
        // 2. if its a file, check the extensions
        let lowercased = file.cleanName.lowercased()
        
        if lowercased.hasSuffix(".wav") || lowercased.hasSuffix(".mp3") || lowercased.hasSuffix(".aif") || lowercased.hasSuffix(".mp4") {
            return Color(red: 255 / 255.0, green: 77 / 255.0, blue: 247 / 255.0, opacity: 1.0)
        } else if lowercased.hasSuffix(".jpg") || lowercased.hasSuffix(".jpeg") || lowercased.hasSuffix(".png") {
            return .yellow
        } else if lowercased.hasSuffix(".pdf") {
            return .green
        } else if lowercased.hasSuffix(".zip") || lowercased.hasSuffix(".rar") {
            return .red
        } else {
            return .blue
        }
    }
    
    func iconFor(file: PixelFile) -> String {
        // 1. Check if it's a follder
        if file.isDirectory {
            return "folder.fill"
        }
        
        // 2. Check extensions for specific fiole types
        let lowercased = file.cleanName.lowercased()
        
        if lowercased.hasSuffix(".wav") || lowercased.hasSuffix(".mp3") || lowercased.hasSuffix(".aif") {
            return "waveform"
        } else if lowercased.hasSuffix("jpg") || lowercased.hasSuffix(".jpeg") || lowercased.hasSuffix(".png") {
            return "photo.fill"
        } else if lowercased.hasSuffix(".pdf") {
            return "doc.text.fill"
        } else if lowercased.hasSuffix("zip") || lowercased.hasSuffix(".rar") {
            return "doc.zipper"
        } else {
            return "doc.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            
            // --- UPDATED HEADER WITH FAQ BUTTON
            HStack {
                Text("Mac-Android File Transfer Utility")
                    .font(.headline)
                Spacer()
                Button(action: {
                    showFAQ = true
                }) {
                    Text("faq") // faq section text
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Folder Naming Input section
            HStack {
                Text("Export Folder Name:")
                TextField("Enter folder name", text: $customFolderName)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal)
            
            
            
            HStack {
                // Home Button
                Button(action: {
                    // Reset everything to the inital landing state
                    currentPath = "/sdcard/Download"
                    searchText = ""
                    forwardHistory.removeAll()
                    refreshCurrentPath()
                }) {
                    Image(systemName: "house.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .disabled(currentPath == "/sdcard/Download")
                .buttonStyle(.plain)
                
                // Back Button
                Button(action: {
                    // "Go Up" one folder logic
                    let components = currentPath.split(separator: "/")
                    if components.count > 1 {
                        // Save the current path to the future history BEFORE going back
                        forwardHistory.append(currentPath)
                        
                        // GO BACK
                        currentPath = "/" + components.dropLast().joined(separator: "/")
                        // Clear search when leaving a folder
                        searchText = ""
                        refreshCurrentPath()
                    }
                }) {
                    // Use a classic "back" arrow icon
                    Image(systemName: "arrow.backward.square.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .disabled(currentPath == "/sdcard") // Stop the user from going too deep into Android system files
                .buttonStyle(.plain)
                
                // FORWARD BUTTON
                Button(action: {
                    // 1. Grab the last saved path from history and remove it from the stack
                    if let nextPath = forwardHistory.popLast() {
                        // 2. Move Forward
                        currentPath = nextPath
                        searchText = ""
                        refreshCurrentPath()
                    }
                }) {
                    Image(systemName: "arrow.forward.square.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                // DIsable the button if there is no future history to jump to
                .disabled(forwardHistory.isEmpty)
                .buttonStyle(.plain)
                
                // PATH TEXT
                Text(currentPath)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.leading, 5) // padding between button and text
                
                Spacer()
            }
            .padding(.horizontal)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search for files or extensions: ", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)    // Stops autocorrection of search text
            }
            .padding(.horizontal)
            
            // --- UPDATED LIST ---
                        
                        // The main file list with selection support
                        List(filteredFiles, id: \.self, selection: $selectedFiles) { file in
                            HStack {
                                // Folders get a yellow folder icon, files use your color function
                                Image(systemName: iconFor(file: file))
                                    .foregroundColor(colorForFile(file: file))
                                
                                Text(file.cleanName)
                                    .lineLimit(1)
                                    .truncationMode(.middle)    // Keeps the beginning of file
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                        .listStyle(.inset)
                        .alternatingRowBackgrounds() // Adds native macOS zebra striping
                        
                        // The official Apple modifier for macOS List double-clicks!
                        .contextMenu(forSelectionType: PixelFile.self) { _ in
                            // We leave the right-click menu empty for now
                            EmptyView()
                        } primaryAction: { items in
                            // This natively fires when a row is double-clicked!
                            if items.count == 1, let file = items.first {
                                if file.isDirectory {
                                    currentPath = "\(currentPath)/\(file.cleanName)"
                                    searchText = ""
                                    forwardHistory.removeAll()
                                    refreshCurrentPath()
                                }
                            }
                        }
            
            
            // Spacer() NEW EDIT: remove to create fixed space
            
            // Progress Bar - only appears during active transfers
            if isDownloading {
                ProgressView("Transferring to Desktop...", value: downloadProgress, total: 1.0)
                    .padding()
            }
            
            HStack {
                
                Spacer() // <--- NEW: Test Alignment
                
                // --- NEW HIDDEN BUTTON ---
                // Select all CMD + A button
                Button("") {
                    // Toggle Logic: if everything visible is already selected, deselect it all
                    // Otherwise, select everything currently visible
                    if selectedFiles.count == filteredFiles.count && !filteredFiles.isEmpty {
                        selectedFiles.removeAll()
                    } else {
                        selectedFiles = Set(filteredFiles)
                    }
                }
                .keyboardShortcut("a", modifiers: .command)
                .hidden()
                
                if isDownloading {
                    // This button only appears during a transfer
                    Button("Cancel Download") {
                        watcher.cancelDownload()
                        isDownloading = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                else {
                    // These buttons appear when the app is idle
                    // Refresh Button to poll ADB for new files
                    Button("Refresh Files") {
                        refreshCurrentPath()
                    }
                    
                   // Spacer() // <-- Separates Left and Right Buttons
                    
                    // Download Selected Button
                    Button("Download Selected") {
                        isDownloading = true
                        downloadProgress = 0.0
                        
                        // Convert the Set to an Array to use your existing bulk download logic
                        let filesToDownload = Array(selectedFiles)
                        
                        DispatchQueue.global(qos: .userInitiated).async {
                            // Pass the array of PixelFiles AND the currentPath
                            watcher.downloadAllFiles(filesToDownload: filesToDownload, sourcePath: currentPath, folderName: folderWithDate) { currentProgress in
                                DispatchQueue.main.async {
                                    self.downloadProgress = currentProgress
                                    if currentProgress >= 1.0 || watcher.shouldCancel {
                                        self.isDownloading = false
                                        if !watcher.shouldCancel {
                                            NSSound(named: "Funk")?.play()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .disabled(selectedFiles.isEmpty || isDownloading)
                    .buttonStyle(.borderedProminent)
                    
                    // Download All Button with background threading
                    Button("Download All Files") {
                        isDownloading = true
                        downloadProgress = 0.0
                        
                        // Move to background thread to prevent UI freezing
                        DispatchQueue.global(qos: .userInitiated).async {
                            // Pass 'files' (which is already PixelFile)
                            watcher.downloadAllFiles(filesToDownload: files, sourcePath: currentPath, folderName: folderWithDate) { currentProgress in
                                // Update UI on the main thread
                                DispatchQueue.main.async {
                                    self.downloadProgress = currentProgress
                                    if currentProgress >= 1.0 || watcher.shouldCancel {
                                        self.isDownloading = false
                                        if !watcher.shouldCancel {
                                            // Audio cue for a lead sound tech
                                            NSSound(named: "Funk")?.play()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer() // NEW: <--- Spacer for Download Buttons
                    
                    Button("Upload to Phone") {
                        let selectedFiles = selectFilesForUpload()
                        
                        if !selectedFiles.isEmpty {
                            // 1. Trigger the progress bar UI
                            print("User selected \(selectedFiles.count) files for upload.")
                            // Engine's 'adb push' funtion here
                            isDownloading = true
                            downloadProgress = 0.0
                            
                            // 2. Move the heavy lifting to a background thread
                            DispatchQueue.global(qos: .userInitiated).async {
                                watcher.uploadFiles(fileURLs: selectedFiles, destinationPath: currentPath) { currentProgress in
                                    
                                    // 3. Update the UI on the main thread
                                    DispatchQueue.main.async {
                                        self.downloadProgress = currentProgress
                                        
                                        // 4. Handle completion
                                        if currentProgress >= 1.0 || watcher.shouldCancel {
                                            self.isDownloading = false
                                            
                                            if !watcher.shouldCancel {
                                                // Audio cue for success
                                                NSSound(named: "Funk")?.play()
                                                // Automatically refresh the folder so new file appears in list
                                                refreshCurrentPath()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    .keyboardShortcut("u", modifiers: .command)
                    .buttonStyle(.borderedProminent)
                    .disabled(files.isEmpty || isDownloading)
                    .padding(.trailing, 13) // Alignment to edge
                    
                } // Closes else box
                
            } // This bracket closes the main HStack
            .padding(.top, 15)
            .padding(.bottom, 20)
             
        } // Closes the main VStack
        
        .padding()
        .frame(minWidth: 550, minHeight: 850) // <-- NEW: Modifiers moved to fix UI
        // Sheet modifier
        .sheet(isPresented: $showFAQ) {
            FAQView()
            }
                
        } // Closes body variable
    } // Closes Content View
    
    // FAQ SCREEN SETUP
    struct FAQItem: View {
        var question: String
        var answer: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(question)
                    .font(.headline)
                
                Text(LocalizedStringKey(answer))
                    .font(.body)
                    .foregroundColor(.secondary)
                // Two lines to force the text to wrap
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
            }
            .padding(.bottom, 10)
        }
    }
    
    // The Main FAQ Window Layout
    struct FAQView: View {
        // This allows the view to dismiss itself
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            VStack(alignment: .leading, spacing: 15) {
                // Header
                HStack {
                    Spacer() // this pushes the close button all the way to the right
                    
                    Button("Close") { dismiss() }
                        .keyboardShortcut(.escape, modifiers: [])
                }
                .overlay(
                    Text("Help & FAQ")
                        .font(.title2)
                        .bold()
                )
                .padding(.top, 25)
                .padding(.horizontal, 25)
                .padding(.bottom, 10)
                
                // --- DIVIDER ---
                Divider()
                    .padding(.horizontal, 25) // match to text margins !
                    .padding(.bottom, 5)
                
                // Scrollable list of questions
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Loop through the static array in FAQData.swift
                        ForEach(0..<FAQData.items.count, id: \.self) { index in
                            FAQItem(
                                question: FAQData.items[index].q,
                                answer: FAQData.items[index].a
                            )
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 20)
                }
                .frame(width: 500, height: 450)
            }
        }
    }

