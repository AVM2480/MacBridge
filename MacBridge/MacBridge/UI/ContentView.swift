import SwiftUI
import UniformTypeIdentifiers

struct PixelFile: Hashable, Identifiable {
    var id: String { cleanName } // Uses the file name as its unique ID
    
    let cleanName: String
    let isDirectory: Bool

    // New data for Get Info window
    var size: String = "Unknown"
    var date: String = "Unknown"
    var permissions: String = "Unknown"
}

struct ContentView: View {
    // --- NEW: Window Opener Tool
    @Environment(\.openWindow) private var openWindow
    
    // State variables for managing data and UI updates
    @State private var files: [PixelFile] = []
    @State private var status = "Needs Refresh"
    @State private var selectedFiles = Set<PixelFile>()
    @State private var searchText = ""
    @State private var currentPath = "/sdcard/Download"
    @State private var forwardHistory: [String] = [] // Forward state saved
    
    // Naming and Progress States
    @State private var customFolderName = "_Pixel_Export"
    @State private var downloadProgress: Double = 0.0
    @State private var isDownloading = false
    @State private var showFAQ = false
    
    @State private var showingDeleteConfirmation = false
    @State private var itemsToDelete: [PixelFile] = []
    @State private var fileToInspect: PixelFile? = nil
    
    // ReNaming States
    @State private var showingRenameAlert = false
    @State private var fileToRename: PixelFile? = nil
    @State private var newFileName = ""
    
    @State private var showingPreviewError = false
    
    // storage variables for preferences
    @AppStorage("showHiddenFiles") private var showHiddenFiles = false
    @AppStorage("playSound") private var playSound = true
    @AppStorage("openFinder") private var openFinder = true
    @AppStorage("appTheme") private var appTheme = "System"
    
    @AppStorage("wirelessIP") private var wirelessIP = ""
    @AppStorage("wirelessPort") private var wirelessPort = "5555"
    @AppStorage("tempConnectionOnly") private var tempConnectionOnly = false
    
    // --- NEW: Custom Routing Var ---
    @AppStorage("defaultAndroidPath") private var defaultAndroidPath = "/sdcard/Download"
    @AppStorage("defaultMacExplortFolder") private var defaultMacExplortFolder = "_Pixel_Export"
    
    let watcher = PixelWatcher()
    
    // Computed property to automatically organize folders by date
    var folderWithDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        return "\(dateString)\(customFolderName)"
    }
    
    var filteredFiles: [PixelFile] {
        // Filter out hidden files if toggle is off
        let visibleFiles = showHiddenFiles ? files : files.filter { !$0.cleanName.hasPrefix(".") }
        
        // Apply the search filter
        if searchText.isEmpty {
            return visibleFiles
        } else {
            return visibleFiles.filter { file in
                file.cleanName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func refreshCurrentPath() {
        // 1. Instantly trigger the loading state before background work starts
        self.status = "Loading..."
        
        selectedFiles.removeAll()
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Catch BOTH the files and the new status
            watcher.listFiles(at: currentPath) { fetchedFiles, newStatus in
                DispatchQueue.main.async {
                    self.files = fetchedFiles
                    self.status = newStatus // Update UI state
                }
            }
        }
    }
    
    // --- TWO FORMS OF UPLOAD ---
    
    // --- MANUAL PICKER (Triggered by your menu and  buttons
    
    func executeUploadProcess() {
        // 1. Summon the Mac file picker
        let selectedURLs = selectFilesForUpload()
        startUpload(for: selectedURLs)
    }
    
    // --- THE MASTER UPLOAD ENGINE (Accepts files from picker or drag-and-drop
    
    func startUpload(for urls: [URL]) {
        if !urls.isEmpty {
            // Lock the UI and reset the progress bar
            isDownloading = true
            downloadProgress = 0.0
                
                // Move to a background thread so the Mac app doesn't freeze!
                DispatchQueue.global(qos: .userInitiated).async {
                    
                    // 5. Fire YOUR exact ADB function!
                    watcher.uploadFiles(fileURLs: urls, destinationPath: currentPath) { progress in
                        // This closure updates the progress bar safely on the main thread
                        DispatchQueue.main.async {
                            self.downloadProgress = progress
                        }
                    }
                    
                   // When finished
                    DispatchQueue.main.async {
                        if playSound { NSSound(named: "Funk")?.play() }
                        self.isDownloading = false
                        self.refreshCurrentPath()
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
        
        // 2. Check extensions for specific file types
        let lowercased = file.cleanName.lowercased()
        
        if lowercased.hasSuffix(".wav") || lowercased.hasSuffix(".mp3") || lowercased.hasSuffix(".aif") {
            return "waveform"
        } else if lowercased.hasSuffix(".jpg") || lowercased.hasSuffix(".jpeg") || lowercased.hasSuffix(".png") {
            return "photo.fill"
        } else if lowercased.hasSuffix(".pdf") {
            return "doc.text.fill"
        } else if lowercased.hasSuffix(".zip") || lowercased.hasSuffix(".rar") {
            return "doc.zipper"
        } else {
            return "doc.fill"
        }
    }
    
    func isSafeToPreview(sizeString: String) -> Bool {
        let cleanSize = sizeString.uppercased()
        
        // Gigabytes are an instant fail
        if cleanSize.contains("GB") { return false }
        
        // KB and Byets re an auto instant pass
        if cleanSize.contains("KB") || cleanSize.contains(" B") { return true }
        
        // If it's MBs, we need to extract the number and check if it's under 20
        if cleanSize.contains("MB") {
            let numberPart = cleanSize.replacingOccurrences(of: " MB", with: "").trimmingCharacters(in: .whitespaces)
            if let size = Double(numberPart), size <= 20.0 {
                return true
            }
            return false
        }
        
        return false // Defaults to safe blocking if it can't read file size
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
                    currentPath = defaultAndroidPath
                    searchText = ""
                    forwardHistory.removeAll()
                    refreshCurrentPath()
                }) {
                    Image(systemName: "house.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .disabled(currentPath == defaultAndroidPath)
                .buttonStyle(.plain)
                
                // Back Button
                Button(action: {
                    // "Go Up" one folder logic
                    var components = currentPath.split(separator: "/")
                    if !components.isEmpty {
                        
                        // Save the current path to the future history BEFORE going back
                        forwardHistory.append(currentPath)
                        
                        // Chop off ONE folder
                        components.removeLast()
                        
                        // Safely rebuild the path
                        currentPath = components.isEmpty ? "/" : "/" + components.joined(separator: "/")
                        
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
                .disabled(currentPath == "/" || currentPath.isEmpty) // Stop the user from going too deep into Android system files
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
            
            // --- NEW: Drag & Drop Zone
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                var droppedURLs: [URL] = []
                let group = DispatchGroup()
                
                // Loop through everything the user just dropped
                for provider in providers {
                    group.enter()
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        if let fileURL = url {
                            DispatchQueue.main.async {
                                droppedURLs.append(fileURL)
                            }
                        }
                        group.leave()
                    }
                }
                // Fed the dropped files to the master engine
                group.notify(queue: .main) {
                    startUpload(for: droppedURLs)
                }
                
                return true
            }
            // --- End of drag and drop zone
            
            // NEW: Overlay Block
            .overlay {
                if status == "Loading..." {
                    VStack(spacing: 8) {
                        Image(systemName: "progress.indicator")
                            .font(.system(.largeTitle, design: .rounded))
                        Text("Loading files")
                            .font(.title3)
                            .bold()
                    }
                    .offset(y: -50)
                    
                    // State 1: Loading
                } else if status == "Needs Refresh" {
                    VStack(spacing: 8) {
                        Image(systemName: "repeat")
                            .font(.system(.largeTitle, design: .rounded))
                        Text("Refresh for files")
                            .font(.title3)
                            .bold()
                    }
                    .offset(y: -50)
                    
                } else if status != "Connected" {
                    
                    // State 2: ADB Error / Disconnected
                    VStack(spacing: 8) {
                        Image(systemName: "iphone.gen2.slash")
                            .font(.system(.largeTitle, design: .rounded))
                        Text(status)
                            .font(.title3)
                            .bold()
                    }
                    .offset(y: -50)
                    
                } else if files.isEmpty && status == "Connected" {
                    
                    // Fallback for actual empty folders
                    VStack(spacing: 8) {
                        Image(systemName: "folder.badge.minus")
                            .font(.system(.largeTitle, design: .rounded))
                        Text("This folder is empty, ya goof!")
                            .font(.title3)
                            .bold()
                    }
                    .offset(y: -50)
                }
            }
            
            // The official Apple modifier for macOS List double-clicks and right clicks
            .contextMenu(forSelectionType: PixelFile.self) { items in
                
                // If User has right clicked at least one file
                if !items.isEmpty {
                    
                    // NEW: Get Info Button (Only shows if exactly 1 file is selected)
                    if items.count == 1, let singleFile = items.first {
                        Button {
                            // Trigger the custom SwiftUI overlay!
                            fileToInspect = singleFile
                        } label: {
                            Label("Get Info", systemImage: "info.circle")
                        }
                        
                        // NEW Preview Button
                        if !singleFile.isDirectory {
                            Button {
                                if isSafeToPreview(sizeString: singleFile.size) {
                                    // Trigger your existing loading overlay
                                    status = "Loading..."
                                    
                                    watcher.previewFile(at: currentPath, fileName: singleFile.cleanName) { success in
                                        // Reset UI when finished
                                        status = "Connected"
                                    }
                                } else {
                                    // The file is over 20MB!
                                    showingPreviewError = true
                                }
                            } label: {
                                Label("Preview", systemImage: "eyes")
                            }
                        }
                        
                        // NEW Rename Button
                        Button {
                            fileToRename = singleFile
                            newFileName = singleFile.cleanName // Pre-fills with existing name
                            showingRenameAlert = true
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        
                        Divider() // Adds a native macOS separator line!
                    }
                    
                    // Delete Button
                    Button(role: .destructive) {
                        // Store files and create trip-wire
                        itemsToDelete = Array(items)
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete From Device", systemImage: "trash")
                    }
                }
            } primaryAction: { items in
                guard let file = items.first else { return }
                
                // The Fix: Use our new boolean instead of checking for a slash
                if file.isDirectory {
                    // NEW: Prevent double slashes like "//sdcard"
                    if currentPath == "/" {
                        currentPath += file.cleanName
                    } else {
                        currentPath += "/\(file.cleanName)"
                    }
                    refreshCurrentPath() // Load function
                }
                
            } // <--  Closes context window
            
            // The Confirmation Dialog Chain
            .confirmationDialog(
                "Are you sure you want to delete these file(s)?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Permanently", role: .destructive) {
                    let pathsToDelete = itemsToDelete.map { "\(currentPath)/\($0.cleanName)" }
                    
                    watcher.deleteItems(paths: pathsToDelete) {
                        if playSound {
                            NSSound(named: "Sosumi")?.play()
                        }
                            self.selectedFiles.removeAll()
                            self.refreshCurrentPath()
                    }
                }
                
                Button("Cancel", role: .cancel) {
                    itemsToDelete.removeAll()
                }
            } message: {
                Text("This action cannot be undone!")
            } // <-- End of .confirmationDialog
            
            // --- Preview Error Alert ---
            .alert("File Too Large to Preview", isPresented: $showingPreviewError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This file is over 20MB. To ensure smooth operation, please download the file to view it.")
            }
            
            // --- The Rename Alert ---
            .alert("Rename File", isPresented: $showingRenameAlert) {
                TextField("New name", text: $newFileName)
                
                Button("Cancel", role: .cancel) {
                    fileToRename = nil
                    newFileName = ""
                }
                
                Button("Rename") {
                    if let file = fileToRename, !newFileName.isEmpty, newFileName != file.cleanName {
                        // We will build this backend function next
                        watcher.renameFile(at: currentPath, oldName: file.cleanName, newName: newFileName) {
                            // Refresh the UI to show the new name
                            refreshCurrentPath()
                        }
                    }
                }
            } message: {
                Text("Enter a new name for this file or folder.")
            }
            
            // The Ultimate Custom Get Info Window
            .overlay {
                if let file = fileToInspect {
                    // 1. Format the data
                    let extensionString = (file.cleanName as NSString).pathExtension.uppercased()
                    let displayType = file.isDirectory ? "Folder" : (extensionString.isEmpty ? "File" : "\(extensionString) File")
                    let displayPermissions = file.permissions.contains("rw") ? "Read & Write" : (file.permissions.contains("r-") ? "Read Only" : file.permissions)
                    
                    // 2. Draw the Floating Window
                    VStack(spacing: 20) {
                        
                        HStack(alignment: .top, spacing: 15) {
                            // Automatically grabs your Mac app's actual icon!
                            Image(nsImage: NSApplication.shared.applicationIconImage ?? NSImage())
                                .resizable()
                                .frame(width: 60, height: 60)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("File Information")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                Text("**Name:** \(file.cleanName)")
                                Text("**Type:** \(displayType)")
                                Text("**Size:** \(file.isDirectory ? "--" : file.size)")
                                Text("**Modified:** \(file.date)")
                                Text("**Permissions:** \(displayPermissions)")
                                
                                Text("**Location:** \(currentPath)/\(file.cleanName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                            
                            Spacer() // <--- NEW: "Spring" to move icon to left
                        }
                        
                        HStack {
                            Spacer()
                            Button("OK") {
                                fileToInspect = nil // Closes the window
                            }
                            .keyboardShortcut(.defaultAction) // Lets you hit Return to close
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            
                            // NEW: Close button
                            Spacer()
                            Button("") {
                                fileToInspect = nil
                            }
                            .keyboardShortcut("w", modifiers: .command)
                            .hidden()
                        }
                    }
                    .padding(20)
                    .frame(width: 400) // Wide enough to hold long file paths
                    .background(.regularMaterial) // Gives the native macOS frosted glass look!
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .offset(y: -75)
                }
            } // <--- .overlay ends here
            
            // Progress Bar - only appears during active transfers
            if isDownloading {
                ProgressView("Transferring File(s)...", value: downloadProgress, total: 1.0)
                    .padding()
            }
            
            HStack {
                
                Spacer() // <--- NEW: Test Alignment
                
                // --- HIDDEN BUTTONS ---
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
                // ---
                // Spacebar to preview
                Button("") {
                    // 1. Only trigger if one file is selected
                    if selectedFiles.count == 1, let singleFile = selectedFiles.first {
                        
                        // 2. Check if it's a folder
                        if !singleFile.isDirectory {
                            
                            // 3. Safety check
                            if isSafeToPreview(sizeString: singleFile.size) {
                                status = "Loading..."
                                watcher.previewFile(at: currentPath, fileName: singleFile.cleanName) { success in
                                    status = "Connected"
                                }
                            } else {
                                showingPreviewError = true
                            }
                        }
                    }
                }
                .keyboardShortcut(.space, modifiers: [])
                .hidden()
                // ---
                
                
                if isDownloading {
                    // This button only appears during a transfer
                    Button("Cancel Download") {
                        watcher.cancelTransfer()
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
                                            if playSound {
                                                NSSound(named: "Funk")?.play()
                                            }
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
                                            if playSound {
                                                NSSound(named: "Funk")?.play()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer() // NEW: <--- Spacer for Download Buttons
                    
                    Button("Upload to Phone") {
                        executeUploadProcess()
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
        .frame(minWidth: 550, minHeight: 600) // <-- NEW: Modifiers moved to fix UI
        
        // --- NEW: Startup Sequence ---
        .onAppear {
            // Check if the user wanted a temp connection
            if tempConnectionOnly {
                // Wipe the saved variables
                wirelessIP = ""
                wirelessPort = "5555"
                
                // Fire the slate wiper to kill anything leftover
                watcher.disconnectEverything()
            }
            
            // Inject the user's save preference
            currentPath = defaultAndroidPath
            customFolderName = defaultMacExplortFolder
            
            // Automatically load the files so user doesn't have to hit refresh
            refreshCurrentPath()
        }
        
        // Sheet modifier
        .sheet(isPresented: $showFAQ) {
            FAQView()
            }
        
        // --- NEW: Notification Listening Center ---
        
        // RENAME from Menu
        
        .onReceive(NotificationCenter.default.publisher(for: .triggerRename)) { _ in
        // SAFETY: Check if only 1 file is selected
            if selectedFiles.count == 1, let singleFile = selectedFiles.first {
                
                // Pre-fill the data
                fileToRename = singleFile
                newFileName = singleFile.cleanName
                
                // Summon alert pop-up
                showingRenameAlert = true
                
                // finish by refreshing
                refreshCurrentPath()
                
            } else {
                // If user hits rename with 0 or > 1 files selected
                NSSound.beep()
            }
        } // --- Close Rename
        
        // DOWNLOAD from menu
        
        .onReceive(NotificationCenter.default.publisher(for: .triggerDownload)) { _ in
            isDownloading = true
            downloadProgress = 0.0
            
            // Conver set to array
            let filesToDownload = Array(selectedFiles)
            
            DispatchQueue.global(qos: .userInitiated).async {
                // Pass the array of PixelFiles AND the currentPath
                watcher.downloadAllFiles(filesToDownload: filesToDownload, sourcePath: currentPath, folderName: folderWithDate) { currentProgress in
                    DispatchQueue.main.async {
                        self.downloadProgress = currentProgress
                        if currentProgress >= 1.0 || watcher.shouldCancel {
                            self.isDownloading = false
                            if !watcher.shouldCancel {
                                if playSound {
                                    NSSound(named: "Funk")?.play()
                                }
                            }
                        }
                    }
                }
            }
        } // --- Closes Download
        
        // DELETE from menu
        
        .onReceive(NotificationCenter.default.publisher(for: .triggerDelete)) { _ in
            
                // Check if files are selected
                if !selectedFiles.isEmpty {
                
                    // Load the array
                    itemsToDelete = Array(selectedFiles)
                    
                    // Load confirmation
                    showingDeleteConfirmation = true
                    
                } else {
                    // Play error sound if nothing is selected
                    NSSound.beep()
                }
            
        } // --- Closes Delete
        
        // UPLOAD from menu
        
        .onReceive(NotificationCenter.default.publisher(for: .triggerUpload)) { _ in
            executeUploadProcess()
        }
        
        // --- Closes Upload
        
        // GET INFO from menu
        
        .onReceive(NotificationCenter.default.publisher(for: .triggerInfo)) { _ in
            // Safety Check: Only one file is selected
            if selectedFiles.count == 1, let singleFile = selectedFiles.first {
                fileToInspect = singleFile
            } else {
                NSSound.beep() // Bonk if 0 or > 1 files selected
            }
        } // --- Closes Get Info
        
        // CANCEL DOWNLOAD from menu
        
        .onReceive(NotificationCenter.default.publisher(for: .triggerCancel)) { _ in
            watcher.shouldCancel = true
            watcher.cancelTransfer()
            isDownloading = false

        } // --- Closes Download
        
        // HELP from menu
        .onReceive(NotificationCenter.default.publisher(for: .triggerHelp)) { _ in
            showFAQ = true
            
        } // --- Closes Help
        
        // ReadMe from menu
        .onReceive(NotificationCenter.default.publisher(for: .triggerReadme)) { _ in
            openWindow(id: "readmeWindow")
            
        } // --- Closes ReadMe
        
        .onReceive(NotificationCenter.default.publisher(for: .triggerRefresh)) { _ in
            // Instantly poll the device for files the second the connection succeeds
            refreshCurrentPath()
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
                    
                    // General FAQ array
                    ForEach(0..<FAQData.generalItems.count, id: \.self) { index in
                        FAQItem(
                            question: FAQData.generalItems[index].q,
                            answer: FAQData.generalItems[index].a
                        )
                    }
                    
                    Divider()
                    
                    // --- THE NEW SUBHEADER ---
                    VStack(alignment: .leading, spacing: 5) {
                        Spacer()
                        
                        
                        Text("Wireless Connectivity Troubleshooting")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 10)
                    // --------------------------
                    
                    // Wireless FAQ array
                    ForEach(0..<FAQData.wirelessItems.count, id: \.self) { index in
                        FAQItem(
                            question: FAQData.wirelessItems[index].q,
                            answer: FAQData.wirelessItems[index].a
                            )
                    }
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 20)
            }
            .frame(width: 450, height: 450)
        }
    }
}

// --- GLOBAL NOTIFICATION SIGNALS ---
extension Notification.Name {
    static let triggerRefresh = Notification.Name("triggerRefresh")
}
