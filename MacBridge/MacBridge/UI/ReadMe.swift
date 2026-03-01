//
//  ReadMe.swift
//  MacBridge
//
//  Created by Abigail on 2/28/26.
//
import SwiftUI

struct ReadmeView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var showShortcuts = false
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("MacBridge ReadMe")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version 1.0")
                    .foregroundColor(.secondary)
                
                Divider()
                
                Text("Getting Started")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Welocome to MacBridge! This utility allows for the seamless transfer of files between your Android phone and MacBook using ADB (Android Debug Bridge). To get started, ensure your device has 'USB Debugging' authorized in Settings and is plugged in with a USB cable that supports data transfer in addition to charging.")
                
                Text("Known Issues & Tips")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 10)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("• If files aren't loading, try unplugging and reconnecting the cable. If the error persists, try using a different cable. Look for the USB trident logo on one end. This symbol indicates data transfer. Charging-only cables will lack this symbol.")
                    
                    Text("• For large transfers, please wait for the success chime before unplugging your device.")
                    
                    Text("• You can permanently delete files using Command + Backspace.")
                    
                    Text("• You can find a full list of key command shortcuts here.")
                    
                    Button("View Keyboard Shortcuts") {
                        showShortcuts = true
                    }
                    .buttonStyle(.bordered)
                    // This attaches the pop-up sheet to the button
                    .sheet(isPresented: $showShortcuts) {
                        ShortcutsView()
                    }
                    
                    
                    }
                
                    Spacer()
            }
            .padding(30)
        }
        // Forces the window to always look like a proper document
        .frame(width: 450, height: 600)
        .background(.background)
    }
}

struct ShortcutsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Keyboard Shortcuts")
                .font(.title2)
                .fontWeight(.bold)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("**Command + U** : Upload")
                Text("**Command + I** : Get Info")
                Text("**Command + R** : Rename")
                Text("**Command + A** : Select All")
                Text("**Command + D** : Download Selected")
                Text("**Command + S** : Cancel Active Transfer")
                Text("**Command + Backspace** : Delete")
                Text("**Command + Y** : Open FAQ")
                Text("**Command + T** : Open ReadMe")
                
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Close") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(25)
            .frame(width: 350, height: 400)
        }
    }
