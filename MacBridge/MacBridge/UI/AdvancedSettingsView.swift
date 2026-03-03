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
                    
                    Button(isRestarting ? "Restarting Server..." : "Restart ADB Server") {
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
                    .padding(.top, 5)
                    
                    }
                
            } else if selectedTab == .wireless {
                
                // --- PLACEHOLDER ---
                Text("Wireless ADB Settings Here")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 40)
            }
            
            Spacer()
        }
        .padding(30)
        
        .onAppear {
            selectedTab = .routing
        }
    }
}

#Preview {
    AdvancedSettingsView()
}
