import SwiftUI
import CoreData

struct ItemDetailView: View {
    @ObservedObject var item: Item
    @Environment(\.managedObjectContext) private var viewContext

    @State private var title: String
    @State private var descriptionText: String
    @State private var mediaType: String
    @State private var url: String
    @State private var favorite: Bool
    @State private var isDownloading: Bool
    @State private var isOnMac: Bool
    @State private var isOnIPhone: Bool
    @State private var isInApp: Bool
    @State private var coverImageData: Data?

    init(item: Item) {
        self.item = item
        _title = State(initialValue: item.title ?? "")
        _descriptionText = State(initialValue: item.descriptionText ?? "")
        _mediaType = State(initialValue: item.mediaType ?? "")
        _url = State(initialValue: item.url ?? "")
        _favorite = State(initialValue: item.favorite)
        _isDownloading = State(initialValue: item.isDownloading)
        _isOnMac = State(initialValue: item.isOnMac)
        _isOnIPhone = State(initialValue: item.isOnIPhone)
        _isInApp = State(initialValue: item.isInApp)
        _coverImageData = State(initialValue: item.coverImage)
    }

    var body: some View {
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
        .navigationTitle(title)
        .onDisappear(perform: saveChanges)
    }

    private func saveChanges() {
        item.title = title.isEmpty ? nil : title
        item.descriptionText = descriptionText
        item.mediaType = mediaType
        item.url = url
        item.favorite = favorite
        item.isDownloading = isDownloading
        item.isOnMac = isOnMac
        item.isOnIPhone = isOnIPhone
        item.isInApp = isInApp
        item.coverImage = coverImageData

        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
