import SwiftUI
import CoreData // Required for Item(context: viewContext)

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss // Use @Environment(\.dismiss) for modern SwiftUI
    @Environment(\.managedObjectContext) private var viewContext // Needed to create a new Item instance

    @State private var title = ""
    @State private var descriptionText = ""
    @State private var mediaType: String = "Book" // Default value, or use an empty string
    @State private var url = ""
    @State private var favorite = false
    @State private var isDownloading = false
    @State private var isOnMac = false
    @State private var isOnIPhone = false
    @State private var isInApp = false
    
    // Media types for the picker
    let availableMediaTypes = ["Book", "Movie", "Song", "Podcast", "Document", "Other"]

    var onSave: (Item) -> Void // Closure to pass the new item back to the parent view

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextField("Description", text: $descriptionText)
                
                // Use a Picker for media type for consistency
                Picker("Media Type", selection: $mediaType) {
                    ForEach(availableMediaTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                
                TextField("URL", text: $url)
                
                Toggle("Favorite", isOn: $favorite)
                Toggle("Downloading", isOn: $isDownloading)
                Toggle("Available on Mac", isOn: $isOnMac)
                Toggle("Available on iPhone", isOn: $isOnIPhone)
                Toggle("In App (e.g. Apple Books)", isOn: $isInApp)
            }
            .navigationTitle("Add Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newItem = Item(context: viewContext)
                        newItem.title = title
                        newItem.descriptionText = descriptionText
                        newItem.mediaType = mediaType
                        newItem.url = url.isEmpty ? nil : url // Store nil if URL is empty
                        newItem.favorite = favorite
                        newItem.isDownloading = isDownloading
                        newItem.isOnMac = isOnMac
                        newItem.isOnIPhone = isOnIPhone
                        newItem.isInApp = isInApp
                        newItem.timestamp = Date()
                        
                        onSave(newItem) // Pass the newly created item back to ContentView
                        dismiss() // Dismiss the sheet
                    }
                    .disabled(title.isEmpty) // Disable save if title is empty
                }
            }
        }
    }
}
