import SwiftUI
import CoreData

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var title = ""
    @State private var descriptionText = ""
    @State private var mediaType: String = "Book"
    @State private var url = ""
    @State private var favorite = false
    @State private var isDownloading = false
    @State private var isOnMac = false
    @State private var isOnIPhone = false
    @State private var isInApp = false
    @State private var coverImageData: Data?

    var onSave: (Item) -> Void

    var body: some View {
        NavigationView {
            ItemFormView(
                title: $title,
                descriptionText: $descriptionText,
                mediaType: $mediaType,
                url: $url,
                favorite: $favorite,
                isDownloading: $isDownloading,
                isOnMac: $isOnMac,
                isOnIPhone: $isOnIPhone,
                isInApp: $isInApp,
                coverImageData: $coverImageData
            )
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
                        newItem.url = url.isEmpty ? nil : url
                        newItem.favorite = favorite
                        newItem.isDownloading = isDownloading
                        newItem.isOnMac = isOnMac
                        newItem.isOnIPhone = isOnIPhone
                        newItem.isInApp = isInApp
                        newItem.timestamp = Date()
                        newItem.coverImage = coverImageData
                        
                        onSave(newItem)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
