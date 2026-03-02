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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            
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
            
            Spacer()
        }
        .padding(30)
    }
}

#Preview {
    AdvancedSettingsView()
}
