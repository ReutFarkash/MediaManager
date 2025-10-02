//
//  ContentView.swift
//  MediaManager
//
//  Created by Reut Farkash on 01/10/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    @State private var showingAddItem = false
    @State private var importInProgress = false
    @State private var selectedItem: Item?

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        VStack(alignment: .leading) {
                            Text(item.title ?? "Untitled").font(.headline)
                            if let desc = item.descriptionText, !desc.isEmpty {
                                Text(desc).font(.subheadline).foregroundColor(.secondary)
                            }
                            HStack {
                                if item.favorite { Image(systemName: "star.fill").foregroundColor(.yellow) }
                                if item.isDownloading { Text("Downloading...").font(.caption).foregroundColor(.blue) }
                                if item.isOnMac { Text("Mac").font(.caption2).foregroundColor(.green) }
                                if item.isOnIPhone { Text("iPhone").font(.caption2).foregroundColor(.green) }
                                if item.isInApp { Text("In App").font(.caption2).foregroundColor(.purple) }
                            }
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: { showingAddItem = true }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                ToolbarItem {
                    Button(action: importBooks) {
                        Label("Import from Apple Books", systemImage: "book")
                    }.disabled(importInProgress)
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView { newItem in
                    withAnimation {
                        viewContext.insert(newItem)
                        do { try viewContext.save() } catch { print(error) }
                    }
                }
            }
            Text("Select an item")
        }
    }

    private func importBooks() {
        importInProgress = true
        DispatchQueue.global(qos: .userInitiated).async {
            let books = BooksImporter.fetchBooks()
            DispatchQueue.main.async {
                for book in books {
                    // Check if book already exists (by title and author)
                    let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "title == %@ AND descriptionText == %@", book.title, book.author)
                    let existing = (try? viewContext.fetch(fetchRequest)) ?? []
                    if existing.isEmpty {
                        let newItem = Item(context: viewContext)
                        newItem.title = book.title
                        newItem.descriptionText = book.author
                        newItem.mediaType = "Book"
                        newItem.isInApp = true
                        newItem.timestamp = Date()
                    }
                }
                do { try viewContext.save() } catch { print(error) }
                importInProgress = false
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            do { try viewContext.save() } catch { let nsError = error as NSError; fatalError("Unresolved error \(nsError), \(nsError.userInfo)") }
        }
    }
}

struct AddItemView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var descriptionText = ""
    @State private var mediaType = ""
    @State private var url = ""
    @State private var favorite = false
    @State private var isDownloading = false
    @State private var isOnMac = false
    @State private var isOnIPhone = false
    @State private var isInApp = false
    var onSave: (Item) -> Void
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextField("Description", text: $descriptionText)
                TextField("Media Type", text: $mediaType)
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
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newItem = Item(context: viewContext)
                        newItem.title = title
                        newItem.descriptionText = descriptionText
                        newItem.mediaType = mediaType
                        newItem.url = url
                        newItem.favorite = favorite
                        newItem.isDownloading = isDownloading
                        newItem.isOnMac = isOnMac
                        newItem.isOnIPhone = isOnIPhone
                        newItem.isInApp = isInApp
                        newItem.timestamp = Date()
                        onSave(newItem)
                        presentationMode.wrappedValue.dismiss()
                    }.disabled(title.isEmpty)
                }
            }
        }
    }
}

struct ItemDetailView: View {
    @ObservedObject var item: Item
    var body: some View {
        Form {
            Text("Title: \(item.title ?? "")")
            Text("Description: \(item.descriptionText ?? "")")
            Text("Media Type: \(item.mediaType ?? "")")
            Text("URL: \(item.url ?? "")")
            Toggle("Favorite", isOn: Binding(get: { item.favorite }, set: { item.favorite = $0 }))
            Toggle("Downloading", isOn: Binding(get: { item.isDownloading }, set: { item.isDownloading = $0 }))
            Toggle("Available on Mac", isOn: Binding(get: { item.isOnMac }, set: { item.isOnMac = $0 }))
            Toggle("Available on iPhone", isOn: Binding(get: { item.isOnIPhone }, set: { item.isOnIPhone = $0 }))
            Toggle("In App (e.g. Apple Books)", isOn: Binding(get: { item.isInApp }, set: { item.isInApp = $0 }))
        }
        .navigationTitle(item.title ?? "Item")
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
