import Foundation

struct FAQData {
    static let items: [(q: String, a: String)] = [
        (
            q: "What does 'No Device Found' mean?",
            a: """
            
            MacBridge cannot detect your phone. Check these three things:
            
            •   **Use a Data Transfer Cable:** 
            
            Ensure your USB cable supports data transfer, not just power delivery. Data cables are usually thicker and often marked with the standard USB trident symbol.
            
            •   **Enable USB Debugging:** 
            
            USB Debugging must be turned on. To reveal this hidden menu, go to Settings > About Phone and tap "Build Number" seven times. Then, navigate to System > Developer Options and toggle USB Debugging ON.
            
            •   **Accept Permissions Prompts:** 
            
            Check both your phone and Mac screens for permission prompts. MacBridge requires these authorizations strictly to enable local data transfers.
            """
        ),
        (
            q: "Where are my files saved when I click download?",
            a: """
            
            They are saved to a new folder on your Mac's Desktop, automatically named using today's date and the custom text you entered above.
            """
        ),
        (
            q: "How do I select multiple files?",
            a: """
            
            •   **Click and Drag:** 
            
            Click and drag your mouse up or down across multiple files to select a specific block.
            
            •   **Select All:** 
            
            Press CMD + A on your keyboard to instantly highlight every file currently visible in the MacBridge window.
            
            •   **Filter & Search:** 
            
            Type a title or an extension (such as .wav or .mp3) into the search field to instantly filter the view for a specific kind of stem or file name.
            """
        )
    ]
}
