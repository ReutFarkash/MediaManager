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
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingAddItem = true }) {
                        Label("Add Item", systemImage: "plus")
                    }
                    .accessibilityIdentifier("Add Item")
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: importBooks) {
                        Label("Import from Apple Books", systemImage: "book")
                    }
                    .accessibilityIdentifier("Import from Apple Books")
                    .disabled(importInProgress)
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView { newItem in
                    // The onSave closure from AddItemView provides the new item.
                    // It's already in the viewContext, so we just need to save.
                    do {
                        try viewContext.save()
                    } catch {
                        print("Error saving new item: \(error.localizedDescription)")
                    }
                }
            }
            Text("Select an item") // Placeholder for split view display
        }
    }

    private func importBooks() {
        importInProgress = true
        Task {
            let books = await BooksImporter.fetchBooks()
            await MainActor.run {
                // 1. Fetch existing book identifiers once for efficient checking.
                let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "mediaType == 'Book'")
                fetchRequest.propertiesToFetch = ["title", "descriptionText"]
                
                let existingBookKeys: Set<String>
                do {
                    let currentItems = try viewContext.fetch(fetchRequest)
                    existingBookKeys = Set(currentItems.compactMap {
                        guard let title = $0.title, let author = $0.descriptionText else { return nil }
                        // Create a unique key for each book.
                        return "\(title)|\(author)"
                    })
                } catch {
                    print("Error fetching existing items: \(error.localizedDescription)")
                    importInProgress = false
                    return
                }

                var hasNewItems = false
                for book in books {
                    // 2. Check against the in-memory set, which is much faster.
                    let bookKey = "\(book.title)|\(book.author)"
                    if !existingBookKeys.contains(bookKey) {
                        let newItem = Item(context: viewContext)
                        newItem.title = book.title
                        newItem.descriptionText = book.author
                        newItem.mediaType = "Book"
                        newItem.isInApp = true
                        newItem.timestamp = Date()
                        hasNewItems = true
                    }
                }

                // 3. Save only if new items were actually added.
                if hasNewItems {
                    do {
                        try viewContext.save()
                    } catch {
                        print("Error saving imported books: \(error.localizedDescription)")
                    }
                }
                importInProgress = false
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                // Avoid fatalError in production code. Log the error for diagnostics.
                // You might want to show an alert to the user here.
                let nsError = error as NSError
                print("Unresolved error deleting item: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
