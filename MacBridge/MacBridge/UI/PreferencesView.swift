import SwiftUI

struct PreferencesView: View {
    // --- Live Storage Variables ---
    @AppStorage("showHiddenFiles") private var showHiddenFiles = false
    @AppStorage("playSound") private var playSound = true
    @AppStorage("openFinder") private var openFinder = true
    
    @AppStorage("appTheme") private var appTheme = "System"
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var activeTab = 0
    
    var body: some View {
        TabView(selection: $activeTab) {
            
            // General Settings Tab
            VStack(alignment: .leading, spacing: 20) {
                Text("App Preferences")
                    .font(.headline)
                
                // Wire 'toggles' to storage variables
                Toggle("Show hidden files", isOn: $showHiddenFiles)
                Toggle("Play notification sounds", isOn: $playSound)
                Toggle("Open finder window when transfer finishes", isOn: $openFinder)
                
                Divider()
                
                // Appearance Picker
                VStack(alignment: .leading, spacing: 20) {
                    Text("Appearance")
                        .font(.headline)
                    
                    Picker("Theme", selection: $appTheme) {
                        Text("System Default").tag("System")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                }
                
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
            .tag(0)
            
            // --- UPDATED ADVANCED TAB ---
           AdvancedSettingsView() // <-- Summons new file!
                .tabItem {
                    Label("Advanced", systemImage: "terminal")
                }
                .tag(1)
            
        } // <--- 1. TabView closes here!
        .frame(width: 450, height: 350) // <--- 2. Frame sizes the whole window safely outside the tabs
        
        .onAppear {
            activeTab = 0
        }
        
    } // <--- 3. body variable closes here
} // <--- 4. NEW: Struct closes here, making the file completely valid!
