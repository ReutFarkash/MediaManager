import Testing
import CoreData
@testable import MediaManager // Import your app module to access internal types

// MARK: - NSPersistentContainer Extension for Async Loading

// This extension allows `NSPersistentContainer.loadPersistentStores` to be used with async/await.
extension NSPersistentContainer {
    func loadPersistentStoresAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            loadPersistentStores { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

// MARK: - CoreDataTestStack

/// A helper class to provide an isolated in-memory Core Data stack for tests.
class AsyncCoreDataTestStack {
    let container: NSPersistentContainer
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }

    /// Initializes an in-memory Core Data stack.
    /// - Throws: An error if the persistent stores cannot be loaded.
    init() async throws {
        container = NSPersistentContainer(name: "MediaManager") // Use your project's data model name
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        description.type = NSInMemoryStoreType // Explicitly specify in-memory
        container.persistentStoreDescriptions = [description]
        
        try await container.loadPersistentStoresAsync()
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    /// Clears all `Item` entities from the test context.
    /// - Throws: An error if the delete operation fails.
    func clearData() async throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Item.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        // Use a background context for batch delete if needed, but for simple tests viewContext is fine.
        try await viewContext.perform { // Use performAndWait for synchronous execution on context
            try self.viewContext.execute(batchDeleteRequest)
        }
        // No explicit save needed after batch delete, as it directly modifies the store.
    }
}

// MARK: - Core Data Operations Tests

@Suite("Core Data Operations Tests")
struct CoreDataTests {

    @Test("Add and Fetch Item")
    func testAddItem() async throws {
        let testStack = try await AsyncCoreDataTestStack()
        let context = testStack.viewContext
        
        let newItem = Item(context: context)
        newItem.title = "Test Book"
        newItem.descriptionText = "A test author"
        newItem.mediaType = "Book"
        newItem.timestamp = Date()

        try context.save()

        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        let items = try context.fetch(fetchRequest)

        #expect(items.count == 1)
        #expect(items.first?.title == "Test Book")
        #expect(items.first?.descriptionText == "A test author")
    }

    @Test("Delete Item")
    func testDeleteItem() async throws {
        let testStack = try await AsyncCoreDataTestStack()
        let context = testStack.viewContext
        
        let newItem = Item(context: context)
        newItem.title = "Item to Delete"
        newItem.timestamp = Date()
        try context.save()

        var items = try context.fetch(Item.fetchRequest())
        #expect(items.count == 1)

        context.delete(newItem)
        try context.save()

        items = try context.fetch(Item.fetchRequest())
        #expect(items.count == 0)
    }

    @Test("Update Item")
    func testUpdateItem() async throws {
        let testStack = try await AsyncCoreDataTestStack()
        let context = testStack.viewContext
        
        let item = Item(context: context)
        item.title = "Original Title"
        item.mediaType = "Original Type"
        item.favorite = false
        item.timestamp = Date()
        try context.save()

        // Simulate ItemDetailView modifying the item
        item.title = "Updated Title"
        item.mediaType = "Updated Type"
        item.favorite = true

        try context.save() // Simulate ItemDetailView's implicit save

        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        let fetchedItems = try context.fetch(fetchRequest)

        #expect(fetchedItems.count == 1)
        #expect(fetchedItems.first?.title == "Updated Title")
        #expect(fetchedItems.first?.mediaType == "Updated Type")
        #expect(fetchedItems.first?.favorite == true)
    }
    
    @Test("Add item with empty URL should store an empty string")
    func testAddItemWithEmptyURL() async throws {
        let testStack = try await AsyncCoreDataTestStack()
        let context = testStack.viewContext
        
        let newItem = Item(context: context)
        newItem.title = "Item with No URL"
        newItem.url = ""
        newItem.timestamp = Date()
        try context.save()
        
        let fetchedItem = try #require(context.fetch(Item.fetchRequest()).first)
        #expect(fetchedItem.url == "")
    }
}

// MARK: - BooksImporter Tests

@Suite("BooksImporter Tests")
struct BooksImporterTests {
    
    @Test("Parse single valid book entry")
    @MainActor
    func testParseSingleBook() {
        let output = "Book Title||Book Author;;"
        let books = BooksImporter.parseBooks(from: output)
        #expect(books.count == 1)
        #expect(books.first?.title == "Book Title")
        #expect(books.first?.author == "Book Author")
    }

    @Test("Parse multiple valid book entries")
    @MainActor
    func testParseMultipleBooks() {
        let output = "Book One||Author One;;Book Two||Author Two;;"
        let books = BooksImporter.parseBooks(from: output)
        #expect(books.count == 2)
        #expect(books[0].title == "Book One")
        #expect(books[0].author == "Author One")
        #expect(books[1].title == "Book Two")
        #expect(books[1].author == "Author Two")
    }

    @Test("Handle malformed book entry (missing author)")
    @MainActor
    func testParseMalformedMissingAuthor() {
        let output = "Book Title||;;" // Missing author, but "||" is present
        let books = BooksImporter.parseBooks(from: output)
        #expect(books.count == 1)
        #expect(books.first?.title == "Book Title")
        #expect(books.first?.author == "") // Empty string author is acceptable
    }
    
    @Test("Handle malformed book entry (missing title)")
    @MainActor
    func testParseMalformedMissingTitle() {
        let output = "||Book Author;;" // Missing title
        let books = BooksImporter.parseBooks(from: output)
        #expect(books.isEmpty) // Entry with empty title should be skipped by the parser
    }

    @Test("Handle malformed book entry (incorrect delimiter count)")
    @MainActor
    func testParseMalformedDelimiterCount() {
        let output = "Book Title|Book Author;;" // Incorrect field delimiter
        let books = BooksImporter.parseBooks(from: output)
        #expect(books.isEmpty)
    }
    
    @Test("Handle malformed book entry (extra delimiter)")
    @MainActor
    func testParseMalformedExtraDelimiter() {
        let output = "Book Title||Book Author||Extra Field;;" // Too many delimiters
        let books = BooksImporter.parseBooks(from: output)
        #expect(books.isEmpty)
    }

    @Test("Handle empty output string")
    @MainActor
    func testParseEmptyOutput() {
        let output = ""
        let books = BooksImporter.parseBooks(from: output)
        #expect(books.isEmpty)
    }
    
    @Test("Handle whitespace around fields")
    @MainActor
    func testParseWhitespace() {
        let output = "  Book Title  ||  Book Author  ;;"
        let books = BooksImporter.parseBooks(from: output)
        #expect(books.count == 1)
        #expect(books.first?.title == "Book Title")
        #expect(books.first?.author == "Book Author")
    }
    
    @Test("Handle multiple entries with mixed valid/invalid")
    @MainActor
    func testParseMixedEntries() {
        let output = "Valid Book||Valid Author;;Malformed||;;Another Valid||Author;;||Bad Title;;"
        let books = BooksImporter.parseBooks(from: output)
        #expect(books.count == 3) // "Valid Book" and "Another Valid" should be parsed
        #expect(books[0].title == "Valid Book")
        #expect(books[1].title == "Malformed")
        #expect(books[2].title == "Another Valid")
    }
    
    // Note: Testing BooksImporter.fetchBooks() directly would execute osascript,
    // which is generally avoided in unit tests as it depends on external applications
    // and environment. For such integration, a UI test or a dedicated integration test
    // that mocks the system call would be more appropriate.
}
