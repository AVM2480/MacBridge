import SwiftUI

// NEW
extension Notification.Name {
    static let triggerRename = Notification.Name("triggerRename")
    static let triggerDownload = Notification.Name("triggerDownload")
    static let triggerDelete = Notification.Name("triggerDelete")
    static let triggerCancel = Notification.Name("triggerCancel")
    static let triggerInfo = Notification.Name("triggerInfo")
    static let triggerUpload = Notification.Name("triggerUpload")
    static let triggerHelp = Notification.Name("triggerHelp")
    static let triggerReadme = Notification.Name("triggerReadme")
}



@main
struct MacBridgeApp: App {
    
    @AppStorage("appTheme") private var appTheme = "System"
    
    // 1. Add this init block to force it to behave like a normal app
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
            
                // Add this modifier to steal keyboard focus
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    applyTheme()
                }
                .onChange(of: appTheme) {
                    applyTheme()
                }
        }
        // --- 1. EDIT THE TOP MENU BAR ---
        .commands {
            // (Notice we completely removed the rebellious .appSettings override!)

            // Add a brand new custom dropdown menu called "Transfer"
            CommandMenu("Transfer") {
               
                Button("Download Selected") {
                    NotificationCenter.default.post(name: .triggerDownload, object: nil)
                }
                .keyboardShortcut("d", modifiers: .command)
                
                Button("Cancel Active Download") {
                    NotificationCenter.default.post(name: .triggerCancel, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Divider() // Separator line
                
                Button("Upload...") {
                    NotificationCenter.default.post(name: .triggerUpload, object: nil)
                }
                .keyboardShortcut("u", modifiers: .command)
            }
            
            // Modify an existing Apple menu (like the "Help" menu)
            CommandGroup(replacing: .help) {
                Button("MacBridge FAQ") {
                    NotificationCenter.default.post(name: .triggerHelp, object: nil)
                    }
                .keyboardShortcut("y", modifiers: .command)
                
                Button("ReadMe") {
                    NotificationCenter.default.post(name: .triggerReadme, object: nil)
                    }
                    .keyboardShortcut("t", modifiers: .command)
                
                } // -- end of Help 
            
            
            CommandGroup(after: .undoRedo) {
                
                Divider()
                
                Button("Rename File") {
                    // Broadcast notification to the rest of app
                    NotificationCenter.default.post(name: .triggerRename, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Button("Get Info") {
                    // Broadcast...
                    NotificationCenter.default.post(name: .triggerInfo, object: nil)
                }
                .keyboardShortcut("i", modifiers: .command)
                
            }
            
            /* CommandGroup(after: .pasteboard) {
                
                Divider()
                
                Button("Delete File Forever") {
                    // Broadcast
                    NotificationCenter.default.post(name: .triggerDelete, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: .command)
                
            } */
           
           
            
            // --- REBUILDING THE PASTEBOARD WITH A DANGER ZONE ---
                        CommandGroup(replacing: .pasteboard) {
                            
                            // 1. The Safe Zone
                            Button("Cut") { NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil) }
                                .keyboardShortcut("x", modifiers: .command)
                            
                            Button("Copy") { NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil) }
                                .keyboardShortcut("c", modifiers: .command)
                            
                            Button("Paste") { NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil) }
                                .keyboardShortcut("v", modifiers: .command)
                            
                            Button("Select All") { NSApp.sendAction(#selector(NSStandardKeyBindingResponding.selectAll(_:)), to: nil, from: nil) }
                                .keyboardShortcut("a", modifiers: .command)
                            
                            // 2. THE MOAT (A visual divider to protect from misclicks)
                            Divider()
                            
                            // 3. The Danger Zone (Isolated at the bottom)
                            Button("Delete File Forever") {
                                NotificationCenter.default.post(name: .triggerDelete, object: nil)
                            }
                            .keyboardShortcut(.delete, modifiers: .command)
                            
                        }
            
            
        }
        
        // --- 2. ADD THE NATIVE SETTINGS WINDOW ---
        // This MUST remain here. It creates both the hidden window AND the menu button!
        Settings {
            PreferencesView()
        }
        
        // --- NEW: ReadMe Window ---
        // Use the ID "readmeWindow" to summon it later
        Window("MacBridge Readme", id: "readmeWindow") {
            ReadmeView()
        }
        // Tells Mac not to stretch beyond current size
        .windowResizability(.contentSize)
        
    } // Closes body
    
    // --- NEW: Theme Enforcer ---

    func applyTheme() {
        if appTheme == "Light" {
            NSApp.appearance = NSAppearance(named: .aqua)
        } else if appTheme == "Dark" {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        } else {
            NSApp.appearance = nil
        }
    }

} // Closes App Struct

