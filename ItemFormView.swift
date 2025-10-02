import SwiftUI

struct ItemFormView: View {
    @Binding var title: String
    @Binding var descriptionText: String
    @Binding var mediaType: String
    @Binding var url: String
    @Binding var favorite: Bool
    @Binding var isDownloading: Bool
    @Binding var isOnMac: Bool
    @Binding var isOnIPhone: Bool
    @Binding var isInApp: Bool
    
    let availableMediaTypes = ["Book", "Movie", "Song", "Podcast", "Document", "Other"]

    var body: some View {
        Form {
            TextField("Title", text: $title)
            TextField("Description", text: $descriptionText)
            
            Picker("Media Type", selection: $mediaType) {
                ForEach(availableMediaTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            
            HStack {
                TextField("URL", text: $url)
                if let url = URL(string: url), !url.absoluteString.isEmpty {
                    Link(destination: url) {
                        Image(systemName: "link")
                            .accessibilityLabel("Open URL")
                    }
                }
            }
            
            Toggle("Favorite", isOn: $favorite)
            Toggle("Downloading", isOn: $isDownloading)
            Toggle("Available on Mac", isOn: $isOnMac)
            Toggle("Available on iPhone", isOn: $isOnIPhone)
            Toggle("In App (e.g. Apple Books)", isOn: $isInApp)
        }
    }
}
