import Foundation 
import IOKit
import IOKit.usb
import SwiftUI
import UniformTypeIdentifiers

class PixelWatcher {
    // Flag to track if the user wants to stop
    var shouldCancel = false

    let googleVendorID: Int = 0x18d1

    func startWatching(onDetected: @escaping () -> Void) {
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary
        matchingDict[kUSBVendorID] = 0x18d1
        matchingDict[kUSBProductID] = 0x4ee1

        guard let notifyPort = IONotificationPortCreate(kIOMainPortDefault) else { return }
        let runLoopSource = IONotificationPortGetRunLoopSource(notifyPort).takeRetainedValue()
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)

        // Wrap the closure so we can pass it as a pointer
        let callbackContext = UnsafeMutableRawPointer(Unmanaged.passRetained(onDetected as AnyObject).toOpaque())

        var iterator: io_iterator_t = 0

        // The callback now pulls the context out of userData
        let matchingCallback: IOServiceMatchingCallback = { (userData, iterator) in
            guard let userData = userData else { return }
            
            // Unwrap the closure from the pointer
            let detectedClosure = Unmanaged<AnyObject>.fromOpaque(userData).takeUnretainedValue() as! () -> Void
            
            while case let device = IOIteratorNext(iterator), device != 0 {
                print("Pixel detected!")
                detectedClosure() // Execute the SwiftUI update
                IOObjectRelease(device)
            }
        }

        IOServiceAddMatchingNotification(
            notifyPort,
            kIOFirstMatchNotification,
            matchingDict,
            matchingCallback,
            callbackContext,
            &iterator
        )

        while case let device = IOIteratorNext(iterator), device != 0 {
            IOObjectRelease(device)
        }
    }

    // --- HELPER FUNCTION FOR ADB & HOMEBREW ---
        private func getADBPath() -> String? {
            
            // THIS BLOCK IS ONLY COMPILED IN VS CODE
            #if DEBUG
            let homebrewPath = "/opt/homebrew/bin/adb"
            if FileManager.default.fileExists(atPath: homebrewPath) {
                print("Notice: Using Homebrew ADB for development.")
                return homebrewPath
            }
            #endif

            // FINAL VERSION 
            if let bundledPath = Bundle.main.path(forResource: "adb", ofType: nil) {
                return bundledPath
            }

            print("CRITICAL ERROR: No ADB binary found anywhere!")
            return nil
        }

    // Now requires a 'path' and returns an array of 'PixelFile'
    func listFiles(at path: String, completion: @escaping ([PixelFile], String) -> Void) {
        let process = Process()
        
        // Find the ADB executable
        guard let adbPath = getADBPath() else {
            print("CRITICAL ERROR: Bundled ADB binary not found!")
            // Safely fail and tell UI what went wrong
            completion([], "ADB Enginge Missing")
            return
        }
        
        process.executableURL = URL(fileURLWithPath: adbPath)
        // The -p flag is the secret to telling files and folders apart
        process.arguments = ["shell", "ls", "-p", "\"\(path)\""]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try? process.run()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        var currentStatus = "Connected"

        if output.contains("unauthorized") {
            print("ACTION REQUIRED: Check Pixel for 'Allow USB Debugging'")
            completion([], "Action Required: Check Phone for 'Allow USB Debugging'")
            return
        } else if output.contains("no devices/emulators found") {
            // Update the status if the device is unplugged
            currentStatus = "No Device Found"
        }

        // Convert the text output into PixelFile objects, filtering out system messages
                let lines = output.components(separatedBy: "\n")
                let files = lines.compactMap { line -> PixelFile? in
                    let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    let lowercasedLine = cleanLine.lowercased()
                    
                    // Ignore empty lines and known ADB system messages
                    if cleanLine.isEmpty ||
                       lowercasedLine.hasPrefix("* daemon") ||
                       lowercasedLine.hasPrefix("adb:") ||
                       lowercasedLine.hasPrefix("error:") ||
                       lowercasedLine.hasPrefix("total") {
                        
                        return nil // Trash this message, don't make it a file!
                    }
                    
                    return PixelFile(rawName: cleanLine, isDirectory: cleanLine.hasSuffix("/"))
                }

        // Sort folders to the top, files to the bottom
        let sortedFiles = files.sorted {
            if $0.isDirectory == $1.isDirectory { return $0.cleanName < $1.cleanName }
            return $0.isDirectory && !$1.isDirectory
        }

        completion(sortedFiles, currentStatus)
    } // <--- THIS WAS THE MISSING BRACKET!

    // Updated single file download to support custom folders
    func downloadFile(fileName: String, toFolder: String) {
        let process = Process()
        guard let adbPath = getADBPath() else {
            print("CRITICAL ERROR: Bundled ADB binary not found!")
            return
        }
        process.executableURL = URL(fileURLWithPath: adbPath)
    
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let destinationFolder = "\(homeDir)/Desktop/\(toFolder)"
    
        // Ensure the custom folder exists
        try? FileManager.default.createDirectory(atPath: destinationFolder, withIntermediateDirectories: true)
    
        process.arguments = ["pull", "/sdcard/Download/\(fileName)", "\(destinationFolder)/\(fileName)"]
    
        try? process.run()
        process.waitUntilExit()

        // Code to open folder once download is finished
        DispatchQueue.main.async {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: destinationFolder)
        }
    }

    // Updated batch download to support progress reporting
    func downloadAllFiles(filesToDownload: [PixelFile], sourcePath: String, folderName: String, progressUpdate: @escaping (Double) -> Void) {
        shouldCancel = false // Reset at start
        // let adbPath = "/opt/homebrew/bin/adb"

        // This tells Swift to look inside internal resources folder
        guard let adbPath = getADBPath() else {
            print("CRITICAL ERROR: Bundled ADB binary not found!")
            return
        }

        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let destinationFolder = "\(homeDir)/Desktop/\(folderName)"
    
        try? FileManager.default.createDirectory(atPath: destinationFolder, withIntermediateDirectories: true)

        for (index, file) in filesToDownload.enumerated() {
            // Check if we should stop before each file
            if shouldCancel {
                print("Download cancelled by user.")
                return
            }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: adbPath)

            // Now dynamically uses the folder you are currently viewing!
            process.arguments = ["pull", "\(sourcePath)/\(file.cleanName)", "\(destinationFolder)/\(file.cleanName)"]
        
            try? process.run()
            process.waitUntilExit()
        
            // Report progress back to the UI
            let currentProgress = Double(index + 1) / Double(filesToDownload.count)
            progressUpdate(currentProgress)
        }

        // If the download finishes naturally and wasn't cancelled, open new folder
        if !shouldCancel {
            DispatchQueue.main.async {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: destinationFolder)
            }
        }
    }

    func cancelDownload() {
        shouldCancel = true
    }
    
    func uploadFiles(fileURLs: [URL], destinationPath: String, progressHandler: @escaping (Double) -> Void) {
        self.shouldCancel = false
        
        let totalFiles = Double(fileURLs.count)
        var completedFiles = 0.0
        
        // Find the ADB executable inside your app bundle
        // (Make sure this matches the path variable used in the download function)
        guard let adbPath = getADBPath() else {
            print("Error: Could not locate adb executable.")
            return
        }
        
        for url in fileURLs {
            if self.shouldCancel { break }
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: adbPath)
            
            // The magic command: adb push <mac_file_path> <android_folder_path>
            process.arguments = ["push", url.path, destinationPath]
            
            do {
                try process.run()
                process.waitUntilExit() // Wait for this file to finish before starting another
            } catch {
                print("Failed to push \(url.lastPathComponent): \(error)")
            }
            
            // Update the loading bar
            completedFiles += 1.0
            let currentProgress = completedFiles / totalFiles
            progressHandler(currentProgress)
        }
    }
    
} // <-- This correctly closes the PixelWatcher class now.

func selectFilesForUpload() -> [URL] {
    let panel = NSOpenPanel()
    
    // 1. Configure the panel's behavior
    panel.allowsMultipleSelection = true
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    
    // 2. Customize the text
    panel.title = "Select files to upload"
    panel.message = "Choose the files you want to transfer to your device."
    panel.prompt = "Upload" // Changes the default "Open" button text
    
    // 3. Restrict selectable file types (Optional)
    // panel.allowedContentTypes = [ ... ]
    
    // 4. Summon the window and wait for user
    if panel.runModal() == .OK {
        // The user clicks "Upload", return the array of file paths
        return panel.urls
    } else {
        // The user clicks "Cancel" or closes the window
        return[]
    }
}

// Ensure this struct is OUTSIDE the PixelWatcher class braces
@main
struct MacBridgeApp: App {
    // 1. Add this init block to force it to behave like a normal app
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 2. Add this modifier to steal keyboard focus
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
    }
}
