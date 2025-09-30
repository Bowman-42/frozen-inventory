# Mobile App Integration Guide

This guide helps mobile app developers integrate with the Frozen Inventory API for barcode-based inventory management.

## Overview

The Frozen Inventory API is designed for mobile applications that use barcode scanning to manage inventory across multiple refrigerator/freezer locations. The typical workflow involves:

1. Scanning location barcodes (QR codes on fridges)
2. Scanning item barcodes (product UPCs/barcodes)
3. Adding or removing items from inventory
4. Viewing current inventory status

## Integration Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │    │  Frozen Inv.    │    │    Database     │
│                 │    │     API         │    │                 │
│ ┌─────────────┐ │    │                 │    │  ┌───────────┐  │
│ │   Barcode   │ │◄──►│  RESTful API    │◄──►│  │ SQLite DB │  │
│ │   Scanner   │ │    │                 │    │  │           │  │
│ └─────────────┘ │    │  JSON Responses │    │  └───────────┘  │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │                 │    │                 │
│ │ Inventory   │ │    │                 │    │                 │
│ │ Management  │ │    │                 │    │                 │
│ └─────────────┘ │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Prerequisites

- HTTP client library for your platform (iOS: URLSession, Android: Retrofit/OkHttp)
- JSON parsing capability
- Barcode scanning library (iOS: AVFoundation, Android: ML Kit)
- Network connectivity

## Base Configuration

```swift
// iOS Swift Example
struct APIConfig {
    static let baseURL = "http://your-server.com/api/v1"
    static let timeout: TimeInterval = 30.0
}
```

```kotlin
// Android Kotlin Example
object APIConfig {
    const val BASE_URL = "http://your-server.com/api/v1/"
    const val TIMEOUT_SECONDS = 30L
}
```

## Core Integration Steps

### 1. System Health Check

Before using the app, verify the server is accessible:

```swift
// iOS Swift
func checkSystemHealth() async throws -> SystemStatus {
    let url = URL(string: "\(APIConfig.baseURL)/status")!
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw APIError.serverError
    }

    let statusResponse = try JSONDecoder().decode(StatusResponse.self, from: data)
    return statusResponse.data
}
```

```kotlin
// Android Kotlin
suspend fun checkSystemHealth(): SystemStatus {
    val response = apiService.getSystemStatus()
    if (response.isSuccessful) {
        return response.body()?.data ?: throw APIException("No data received")
    } else {
        throw APIException("Server error: ${response.code()}")
    }
}
```

### 2. Location Scanning Integration

When a user scans a location barcode:

```swift
// iOS Swift
func processLocationBarcode(_ barcode: String) async {
    do {
        let location = try await getLocation(barcode: barcode)
        // Update UI with location details
        updateLocationView(location)
    } catch {
        // Handle error - show user-friendly message
        showError("Fridge not found. Please check the barcode.")
    }
}

func getLocation(barcode: String) async throws -> Location {
    let url = URL(string: "\(APIConfig.baseURL)/locations/\(barcode)")!
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIError.networkError
    }

    if httpResponse.statusCode == 404 {
        throw APIError.locationNotFound
    }

    guard httpResponse.statusCode == 200 else {
        throw APIError.serverError
    }

    let locationResponse = try JSONDecoder().decode(LocationResponse.self, from: data)
    return locationResponse.data
}
```

```kotlin
// Android Kotlin
suspend fun processLocationBarcode(barcode: String) {
    try {
        val location = apiService.getLocation(barcode)
        if (location.isSuccessful) {
            // Update UI with location details
            updateLocationView(location.body()?.data)
        } else {
            handleAPIError(location.code())
        }
    } catch (e: Exception) {
        showError("Unable to connect to server")
    }
}
```

### 3. Item Scanning and Addition

When a user scans an item barcode to add it:

```swift
// iOS Swift
func addItemToLocation(locationBarcode: String, itemBarcode: String, quantity: Int) async {
    do {
        let result = try await addItem(
            locationBarcode: locationBarcode,
            itemBarcode: itemBarcode,
            quantity: quantity
        )
        // Show success message
        showSuccess(result.message ?? "Item added successfully")
        // Refresh location inventory
        refreshLocationInventory(locationBarcode)
    } catch {
        handleAddItemError(error)
    }
}

func addItem(locationBarcode: String, itemBarcode: String, quantity: Int) async throws -> AddItemResponse {
    let url = URL(string: "\(APIConfig.baseURL)/add-item")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let requestBody = AddItemRequest(
        locationBarcode: locationBarcode,
        itemBarcode: itemBarcode,
        quantity: quantity
    )

    request.httpBody = try JSONEncoder().encode(requestBody)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIError.networkError
    }

    if httpResponse.statusCode == 404 {
        throw APIError.resourceNotFound
    }

    if httpResponse.statusCode == 422 {
        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
        throw APIError.validationError(errorResponse.error)
    }

    guard httpResponse.statusCode == 200 else {
        throw APIError.serverError
    }

    return try JSONDecoder().decode(AddItemResponse.self, from: data)
}
```

```kotlin
// Android Kotlin
suspend fun addItemToLocation(locationBarcode: String, itemBarcode: String, quantity: Int) {
    try {
        val request = AddItemRequest(locationBarcode, itemBarcode, quantity)
        val response = apiService.addItem(request)

        if (response.isSuccessful) {
            showSuccess(response.body()?.message ?: "Item added successfully")
            refreshLocationInventory(locationBarcode)
        } else {
            handleAPIError(response.code(), response.errorBody()?.string())
        }
    } catch (e: Exception) {
        showError("Unable to add item: ${e.message}")
    }
}
```

### 4. Item Removal

When a user removes items:

```swift
// iOS Swift
func removeItemFromLocation(locationBarcode: String, itemBarcode: String, quantity: Int) async {
    do {
        let result = try await removeItem(
            locationBarcode: locationBarcode,
            itemBarcode: itemBarcode,
            quantity: quantity
        )
        showSuccess(result.message ?? "Item removed successfully")
        refreshLocationInventory(locationBarcode)
    } catch APIError.itemNotInLocation {
        showError("This item is not in the selected location")
    } catch {
        handleRemoveItemError(error)
    }
}
```

## Data Models

### iOS Swift Models

```swift
struct SystemStatus: Codable {
    let status: String
    let version: String
    let timestamp: String
    let database: DatabaseInfo
}

struct DatabaseInfo: Codable {
    let connected: Bool
    let locationsCount: Int
    let itemsCount: Int
    let inventoryItemsCount: Int

    enum CodingKeys: String, CodingKey {
        case connected
        case locationsCount = "locations_count"
        case itemsCount = "items_count"
        case inventoryItemsCount = "inventory_items_count"
    }
}

struct Location: Codable {
    let id: Int
    let name: String
    let barcode: String
    let description: String?
    let totalItems: Int
    let inventoryItems: [InventoryItem]

    enum CodingKeys: String, CodingKey {
        case id, name, barcode, description
        case totalItems = "total_items"
        case inventoryItems = "inventory_items"
    }
}

struct Item: Codable {
    let id: Int
    let name: String
    let barcode: String
    let description: String?
}

struct InventoryItem: Codable {
    let item: Item
    let quantity: Int
    let addedAt: String

    enum CodingKeys: String, CodingKey {
        case item, quantity
        case addedAt = "added_at"
    }
}

struct AddItemRequest: Codable {
    let locationBarcode: String
    let itemBarcode: String
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case locationBarcode = "location_barcode"
        case itemBarcode = "item_barcode"
        case quantity
    }
}
```

### Android Kotlin Models

```kotlin
data class SystemStatus(
    val status: String,
    val version: String,
    val timestamp: String,
    val database: DatabaseInfo
)

data class DatabaseInfo(
    val connected: Boolean,
    @SerializedName("locations_count") val locationsCount: Int,
    @SerializedName("items_count") val itemsCount: Int,
    @SerializedName("inventory_items_count") val inventoryItemsCount: Int
)

data class Location(
    val id: Int,
    val name: String,
    val barcode: String,
    val description: String?,
    @SerializedName("total_items") val totalItems: Int,
    @SerializedName("inventory_items") val inventoryItems: List<InventoryItem>
)

data class Item(
    val id: Int,
    val name: String,
    val barcode: String,
    val description: String?
)

data class InventoryItem(
    val item: Item,
    val quantity: Int,
    @SerializedName("added_at") val addedAt: String
)

data class AddItemRequest(
    @SerializedName("location_barcode") val locationBarcode: String,
    @SerializedName("item_barcode") val itemBarcode: String,
    val quantity: Int
)
```

## Error Handling Best Practices

### User-Friendly Error Messages

```swift
// iOS Swift
enum APIError: Error {
    case networkError
    case serverError
    case locationNotFound
    case itemNotFound
    case itemNotInLocation
    case validationError(String)

    var userMessage: String {
        switch self {
        case .networkError:
            return "Unable to connect. Please check your internet connection."
        case .serverError:
            return "Server error. Please try again later."
        case .locationNotFound:
            return "Fridge not found. Please scan the correct barcode."
        case .itemNotFound:
            return "Item not found. Please scan the correct barcode."
        case .itemNotInLocation:
            return "This item is not stored in the selected fridge."
        case .validationError(let message):
            return message
        }
    }
}
```

### Offline Support

```swift
// iOS Swift - Simple offline queue
class OfflineManager {
    private var pendingOperations: [PendingOperation] = []

    func queueOperation(_ operation: PendingOperation) {
        pendingOperations.append(operation)
        saveToStorage()
    }

    func processPendingOperations() async {
        for operation in pendingOperations {
            do {
                try await processOperation(operation)
                removePendingOperation(operation)
            } catch {
                // Keep for retry
                print("Failed to process operation: \(error)")
            }
        }
    }
}
```

## Performance Optimization

### Caching Strategy

```swift
// iOS Swift - Simple caching
class LocationCache {
    private var cache: [String: Location] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes

    func getLocation(barcode: String) async throws -> Location {
        if let cached = cache[barcode],
           cached.lastUpdated.timeIntervalSinceNow > -cacheTimeout {
            return cached
        }

        let fresh = try await fetchLocationFromAPI(barcode: barcode)
        cache[barcode] = fresh
        return fresh
    }
}
```

### Network Request Optimization

- Use connection pooling
- Implement request timeouts (30 seconds recommended)
- Cache frequently accessed data
- Use compression for large responses

## Security Considerations

1. **HTTPS**: Always use HTTPS in production
2. **Certificate Pinning**: Pin server certificates for additional security
3. **Input Validation**: Validate barcodes before sending to API
4. **Error Information**: Don't expose sensitive error details to users

## Testing Integration

### Unit Tests

```swift
// iOS Swift - Testing API integration
class APITests: XCTestCase {
    func testGetLocationSuccess() async throws {
        let api = APIClient(baseURL: "http://test-server.com")
        let location = try await api.getLocation(barcode: "FRIDGE001")

        XCTAssertEqual(location.barcode, "FRIDGE001")
        XCTAssertNotNil(location.name)
    }

    func testGetLocationNotFound() async {
        let api = APIClient(baseURL: "http://test-server.com")

        do {
            _ = try await api.getLocation(barcode: "INVALID")
            XCTFail("Should have thrown locationNotFound error")
        } catch APIError.locationNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
```

## Production Deployment

### Server Requirements

- Ensure server has proper SSL certificate
- Configure proper CORS headers if needed
- Set up monitoring and logging
- Implement proper backup procedures

### App Store Considerations

- Include camera usage description for barcode scanning
- Test with various barcode formats
- Handle network connectivity changes gracefully
- Provide offline functionality where possible

## Support and Troubleshooting

Common issues and solutions:

1. **Barcode not recognized**: Ensure proper barcode format and database entries
2. **Network timeouts**: Implement retry logic with exponential backoff
3. **Server errors**: Check server logs and implement proper error reporting
4. **Cache issues**: Implement cache invalidation strategies