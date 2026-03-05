//
//  AdvancedSettingsView.swift
//  MacBridge
//
//  Created by Abigail on 3/2/26.
//

import SwiftUI

struct AdvancedSettingsView: View {
    
    // @AppStorage automatically saves these to the Mac's permanent UserDefautls
    @AppStorage("defualtAndroidPath") private var defaultAndroidPath = "/sdcard/Download"
    @AppStorage("defualtMacExportFolder") private var defaultMacExportFolder = "_Pixel_Export"
    
    @AppStorage("wirelessIP") private var wirelessIP = ""
    @AppStorage("wirelessPort") private var wirelessPort = "5555" // 5555 is the Android default
    
    @AppStorage("tempConnectionOnly") private var tempConnectionOnly = false
    
    @Environment(\.dismiss) var dismiss
    
    @State private var connectionStatus = ""
    @State private var isConnecting = false
    @State private var isPairingMode = false
    @State private var wirelessPIN = ""
    
    let watcher = PixelWatcher()
    @State private var isRestarting = false
    
    // --- NEW: Subtab Controller ---
    enum AdvancedTab {
        case routing
        case diagnostics
        case wireless
    }
        
    
    @State private var selectedTab: AdvancedTab = .routing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            
            // NEW: Subtab Navigation View
            Picker("", selection: $selectedTab) {
                Text("Routing").tag(AdvancedTab.routing)
                Text("Diagnostics").tag(AdvancedTab.diagnostics)
                Text("Wireless").tag(AdvancedTab.wireless)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 10)
            
            // Conditional UI Blocks
            if selectedTab == .routing {
                
            VStack(alignment: .leading, spacing: 10) {
                Text("Custom Routing")
                    .font(.headline)
                
                Text("Set the default locations MacBridge uses when launching or exporting files.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
                VStack(alignment: .leading, spacing: 15) {
                    // Android Path
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Default Android Path:")
                            .font(.subheadline)
                        TextField("/sdcard/Download", text: $defaultAndroidPath)
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true) // Crucial for file paths!
                    }
                    
                    // Mac Path
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Default Mac Export Folder (on Desktop):")
                            .font(.subheadline)
                        TextField("_Pixel_Export", text: $defaultMacExportFolder)
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                    }
                    
                    // A handy reset button just in case the paths get messed up
                    Button("Restore Default Paths") {
                        defaultAndroidPath = "/sdcard/Download"
                        defaultMacExportFolder = "_Pixel_Export"
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                    // .frame(alignment: .leading) // <-- Alignment tool
                    .padding(.top, 5)
                }
                
                // Spacer()
                // Divider()
                
                
                Button("Close Window") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 25)
                
            } else if selectedTab == .diagnostics {
                // --- NEW: Diagnostics Section ---
                VStack(alignment: .leading, spacing: 10) {
                    Text("Engine Diagnostics")
                        .font(.headline)
                    
                    Text("If MacBridge stops recognizing your device or a transfer permanently freezes, restarting the core ADB engine will usually fix the connection.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    // Allows for long text to wrap cleanly
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button(isRestarting ? "Restarting Engine..." : "Restart ADB Engine") {
                        isRestarting = true
                            
                        // Fire the engine reboot!
                        watcher.restartADBEngine()
                        
                        // Give the UI a 1.5-sec fake delay so the user feels the reboot
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isRestarting = false
                            }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(isRestarting)
                    .padding(.top, 15)
                    
                    }
                
                Spacer()
                Spacer()
                Spacer()
                
                
                
                Button("Close Window") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 25)
               
                
            } else if selectedTab == .wireless {
                
                // --- NEW: Wireless ADB UI ---
                VStack(alignment: .leading, spacing: 15) {
                    
                    // Header & Instructions
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Wiireless ADB Connection")
                            .font(.headline)
                        
                        Text("Conect to your Android device over Wi-Fi.\n\nEnsure that your Mac and device are on the same network, and that the Wi-Fi password match those in the settings on your device.\n\n'Wireless Debugging' must also be enabled in the device's Developer Options.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // --- NEW: The Pairing Toggle ---
                                        Toggle("First-Time Pairing Mode", isOn: $isPairingMode)
                                            .font(.subheadline)
                                            .padding(.bottom, 5)
                    
                    Toggle("Temporary Connection (Forget on Exit)", isOn: $tempConnectionOnly)
                        .font(.subheadline)
                        .padding(.bottom, 10)
                                        
                        // 2. The Input Fields
                        HStack(spacing: 15) {
                        // IP Address Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("IP Address:")
                                .font(.subheadline)
                            TextField("192.168.1.xxx", text: $wirelessIP)
                                .textFieldStyle(.roundedBorder)
                                .disableAutocorrection(true)
                                .frame(width: 140)
                            }
                                            
                        // Port Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isPairingMode ? "Pairing Port:" : "Port:")
                                .font(.subheadline)
                            TextField("5555", text: $wirelessPort)
                                .textFieldStyle(.roundedBorder)
                                .disableAutocorrection(true)
                                .frame(width: 80)
                            }
                                            
                            // PIN Field (ONLY shows when Pairing Mode is ON)
                            if isPairingMode {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("6-Digit PIN:")
                                        .font(.subheadline)
                                    TextField("000000", text: $wirelessPIN)
                                        .textFieldStyle(.roundedBorder)
                                        .disableAutocorrection(true)
                                        .frame(width: 80)
                                }
                            }
                        }
                                        
                        // 3. The Live Connect/Pair Button
                        HStack(spacing: 15) {
                            Button(isConnecting ? "Working..." : (isPairingMode ? "Pair Device" : "Connect to Device")) {
                                isConnecting = true
                                connectionStatus = isPairingMode ? "Attempting to pair..." : "Attempting to connect..."
                                                
                                if isPairingMode {
                                // Use the Pairing Engine you added to PixelWatcher
                                watcher.pairWirelessADB(ip: wirelessIP, port: wirelessPort, code: wirelessPIN) { success, message in
                                DispatchQueue.main.async {
                                    self.isConnecting = false
                                    self.connectionStatus = message
                                    if success { NSSound(named: "Glass")?.play()
                                        NotificationCenter.default.post(name: .triggerRefresh, object: nil)
                                    } else { NSSound(named: "Basso")?.play() }
                                        }
                                    }
                                    } else {
                                // Use the regular Connect Engine
                                watcher.connectWirelessADB(ip: wirelessIP, port: wirelessPort) { success, message in
                                DispatchQueue.main.async {
                                    self.isConnecting = false
                                    self.connectionStatus = message
                                    if success { NSSound(named: "Blow")?.play()
                                
                                // --- NEW: Broadcast Notification
                                NotificationCenter.default.post(name: .triggerRefresh, object: nil)
                                
                                    } else {
                                    NSSound(named: "Basso")?.play() }
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            // Disable button if fields are empty
                            .disabled(wirelessIP.isEmpty || (isPairingMode && wirelessPIN.isEmpty) || isConnecting)
                            
                            // --- NEW: The Disconnect Button ---
                            Button("Disconnect") {
                                // Sever the background connection
                                let watcher = PixelWatcher()
                                watcher.disconnectEverything()
                                
                                // Update the UI Text
                                connectionStatus = "Disconnected" // Disconnected from Device
                                
                                // Trigger the amnesia if temp mode is checked
                                if tempConnectionOnly {
                                    wirelessIP = ""
                                    wirelessPort = "5555"
                                }
                                
                                // Play the disconnect sound
                                NSSound(named: "Hero")?.play()
                                
                                // Broadcast the signal to Main Window to clear file list
                                NotificationCenter.default.post(name: .triggerRefresh, object: nil)
                                }
                            // Use the standard border so it doesn't fight blue button
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .disabled(!connectionStatus.contains ("Successfully"))
                                            
                            // Status text
                            if !connectionStatus.isEmpty {
                            Text(connectionStatus)
                                .font(.caption)
                                .foregroundColor(connectionStatus.contains("Attempting") ? .orange :
                                    connectionStatus.contains("Successfully") ? .green : .red
                                        )
                                    }
                                } // <-- Closes the Buttons HStack
                                .padding(.top, 10)
                    
                            } // <-- Closes the main Wireless VStack
                        } // <-- Closes the 'else if' Tab Stack
            
                        
            
                        Spacer()
                    }
        .padding([.horizontal, .top], 30)
        .padding(.bottom, 15)
        
                    .onAppear {
                        selectedTab = .routing
                    }
                }
            }

#Preview {
    AdvancedSettingsView()
}
