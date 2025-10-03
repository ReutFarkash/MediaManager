import SwiftUI
import CoreData // Required for Item and viewContext

struct ItemDetailView: View {
    @ObservedObject var item: Item // Use @ObservedObject to enable direct editing of item properties
    @Environment(\.managedObjectContext) private var viewContext // Needed to save changes
    @Environment(\.undoManager) var undoManager // Optional: for undo/redo functionality

    var body: some View {
        Form {
            TextField("Title", text: Binding(get: { item.title ?? "" }, set: { item.title = $0; saveChanges() }))
            TextField("Description", text: Binding(get: { item.descriptionText ?? "" }, set: { item.descriptionText = $0; saveChanges() }))
            TextField("Media Type", text: Binding(get: { item.mediaType ?? "" }, set: { item.mediaType = $0; saveChanges() }))
            
            HStack {
                TextField("URL", text: Binding(get: { item.url ?? "" }, set: { item.url = $0.isEmpty ? nil : $0; saveChanges() }))
                if let urlString = item.url, let url = URL(string: urlString), !urlString.isEmpty {
                    Link(destination: url) {
                        Image(systemName: "link")
                            .accessibilityLabel("Open URL")
                    }
                }
            }
            
            Toggle("Favorite", isOn: Binding(get: { item.favorite }, set: { item.favorite = $0; saveChanges() }))
            Toggle("Downloading", isOn: Binding(get: { item.isDownloading }, set: { item.isDownloading = $0; saveChanges() }))
            Toggle("Available on Mac", isOn: Binding(get: { item.isOnMac }, set: { item.isOnMac = $0; saveChanges() }))
            Toggle("Available on iPhone", isOn: Binding(get: { item.isOnIPhone }, set: { item.isOnIPhone = $0; saveChanges() }))
            Toggle("In App (e.g. Apple Books)", isOn: Binding(get: { item.isInApp }, set: { item.isInApp = $0; saveChanges() }))
        }
        .navigationTitle(item.title ?? "Item Details")
        .onDisappear {
            // Ensure any pending changes are saved when the view is dismissed
            saveChanges()
        }
    }

    private func saveChanges() {
        // Only update and save if there are actual changes.
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error saving changes in ItemDetailView: \(nsError), \(nsError.userInfo)")
                // You might want to roll back changes or alert the user.
            }
        }
    }
}
