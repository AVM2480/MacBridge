import SwiftUI

struct PreferencesView: View {
    // --- Live Storage Variables ---
    @AppStorage("showHiddenFiles") private var showHiddenFiles = false
    @AppStorage("playSound") private var playSound = true
    @AppStorage("openFinder") private var openFinder = true
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TabView {
            
            // General Settings Tab
            VStack(alignment: .leading, spacing: 20) {
                Text("App Preferences")
                    .font(.headline)
                
                // Wire 'toggles' to storage variables
                Toggle("Show hidden files", isOn: $showHiddenFiles)
                Toggle("Play notification sounds", isOn: $playSound)
                Toggle("Open finder window when transfer finishes", isOn: $openFinder)
                
                Spacer()
                
                Button("Close Window") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
            }
            .padding(30)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
            
            // Advanced Settings Tab
            VStack {
                Text("Advanced ADB Options")
                // Return here to build out later
            }
            .padding(30)
            .tabItem {
                Label("Advanced", systemImage: "terminal")
            }
            
        } // <--- 1. TabView closes here!
        .frame(width: 450, height: 250) // <--- 2. Frame sizes the whole window safely outside the tabs
        
    } // <--- 3. body variable closes here
} // <--- 4. NEW: Struct closes here, making the file completely valid!
