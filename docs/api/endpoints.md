# API Endpoints Reference

This document provides detailed information about all available API endpoints in the Frozen Inventory system.

## System Status

### GET /api/v1/status

Returns system health information and database statistics.

**Request:**
```http
GET /api/v1/status
```

**Response:**
```json
{
  "data": {
    "status": "ok",
    "version": "1.0.0",
    "timestamp": "2024-01-15T10:30:00Z",
    "database": {
      "connected": true,
      "locations_count": 5,
      "items_count": 150,
      "inventory_items_count": 300
    }
  }
}
```

**Status Codes:**
- `200 OK` - System is healthy
- `500 Internal Server Error` - System error

---

## Location Endpoints

### GET /api/v1/locations/{barcode}

Retrieves details about a specific location (fridge/freezer) and its contents.

**Parameters:**
- `barcode` (path parameter) - Unique barcode identifier for the location

**Request:**
```http
GET /api/v1/locations/FRIDGE001
```

**Response:**
```json
{
  "data": {
    "id": 1,
    "name": "Main Kitchen Fridge",
    "barcode": "FRIDGE001",
    "description": "Main refrigerator in the kitchen",
    "total_items": 15,
    "inventory_items": [
      {
        "item": {
          "id": 1,
          "name": "Whole Milk",
          "barcode": "ITEM001",
          "description": "1 gallon whole milk"
        },
        "quantity": 2,
        "added_at": "2024-01-15T09:00:00Z"
      },
      {
        "item": {
          "id": 2,
          "name": "Sourdough Bread",
          "barcode": "ITEM002",
          "description": "Fresh sourdough loaf"
        },
        "quantity": 1,
        "added_at": "2024-01-15T10:15:00Z"
      }
    ]
  }
}
```

**Status Codes:**
- `200 OK` - Location found
- `404 Not Found` - Location with specified barcode not found

---

## Item Endpoints

### GET /api/v1/items/{barcode}

Retrieves details about a specific item and all locations where it's stored.

**Parameters:**
- `barcode` (path parameter) - Unique barcode identifier for the item

**Request:**
```http
GET /api/v1/items/ITEM001
```

**Response:**
```json
{
  "data": {
    "id": 1,
    "name": "Whole Milk",
    "barcode": "ITEM001",
    "description": "1 gallon whole milk",
    "total_quantity": 5,
    "locations": [
      {
        "location": {
          "id": 1,
          "name": "Main Kitchen Fridge",
          "barcode": "FRIDGE001",
          "description": "Main refrigerator in the kitchen"
        },
        "quantity": 2,
        "added_at": "2024-01-15T09:00:00Z"
      },
      {
        "location": {
          "id": 2,
          "name": "Basement Freezer",
          "barcode": "FRIDGE002",
          "description": "Chest freezer in basement"
        },
        "quantity": 3,
        "added_at": "2024-01-15T08:30:00Z"
      }
    ]
  }
}
```

**Status Codes:**
- `200 OK` - Item found
- `404 Not Found` - Item with specified barcode not found

---

## Inventory Management Endpoints

### POST /api/v1/add-item

Adds exactly 1 item to a specific location in the inventory per API call.

**Request Body:**
```json
{
  "location_barcode": "FRIDGE001",
  "item_barcode": "ITEM001"
}
```

**Parameters:**
- `location_barcode` (required) - Barcode of the target location
- `item_barcode` (required) - Barcode of the item to add

**Request:**
```http
POST /api/v1/add-item
Content-Type: application/json

{
  "location_barcode": "FRIDGE001",
  "item_barcode": "ITEM001"
}
```

**Response:**
```json
{
  "data": {
    "inventory_item": {
      "id": 1,
      "quantity": 3,
      "added_at": "2024-01-15T10:30:00Z"
    },
    "location": {
      "id": 1,
      "name": "Main Kitchen Fridge",
      "barcode": "FRIDGE001"
    },
    "item": {
      "id": 1,
      "name": "Whole Milk",
      "barcode": "ITEM001"
    }
  },
  "message": "Item added successfully"
}
```

**Status Codes:**
- `200 OK` - Item added successfully
- `422 Unprocessable Entity` - Validation errors
- `404 Not Found` - Location or item not found

**Behavior:**
- Each API call adds exactly 1 item to the location
- If the item already exists in the location, the quantity is incremented by 1
- If the item doesn't exist in the location, a new inventory entry is created with quantity 1
- The `added_at` timestamp reflects the original addition time for existing entries

---

### POST /api/v1/remove-item

Removes exactly 1 item from a specific location in the inventory per API call.

**Request Body:**
```json
{
  "location_barcode": "FRIDGE001",
  "item_barcode": "ITEM001"
}
```

**Parameters:**
- `location_barcode` (required) - Barcode of the target location
- `item_barcode` (required) - Barcode of the item to remove

**Request:**
```http
POST /api/v1/remove-item
Content-Type: application/json

{
  "location_barcode": "FRIDGE001",
  "item_barcode": "ITEM001"
}
```

**Successful Removal (Partial):**
```json
{
  "data": {
    "inventory_item": {
      "id": 1,
      "quantity": 1,
      "added_at": "2024-01-15T09:00:00Z"
    },
    "removed_quantity": 1,
    "location": {
      "id": 1,
      "name": "Main Kitchen Fridge",
      "barcode": "FRIDGE001"
    },
    "item": {
      "id": 1,
      "name": "Whole Milk",
      "barcode": "ITEM001"
    }
  },
  "message": "Item removed successfully"
}
```

**Complete Removal:**
```json
{
  "data": {
    "message": "Item completely removed from location",
    "removed_quantity": 2,
    "location": {
      "id": 1,
      "name": "Main Kitchen Fridge",
      "barcode": "FRIDGE001"
    },
    "item": {
      "id": 1,
      "name": "Whole Milk",
      "barcode": "ITEM001"
    }
  },
  "message": "Item removed successfully"
}
```

**Status Codes:**
- `200 OK` - Item removed successfully
- `422 Unprocessable Entity` - Validation errors
- `404 Not Found` - Location, item, or inventory entry not found

**Behavior:**
- Each API call removes exactly 1 item from the location
- If the current quantity is greater than 1, the quantity is decremented by 1
- If the current quantity is 1, the inventory entry is completely removed
- Returns the actual quantity that was removed (always 1 or the final quantity if completely removed)

---

## Error Responses

All endpoints can return the following error responses:

### 404 Not Found
```json
{
  "error": "Record not found",
  "message": "Couldn't find Location with 'barcode'=INVALID_BARCODE"
}
```

### 422 Unprocessable Entity
```json
{
  "error": "Location barcode is required"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error occurred"
}
```

## Rate Limiting

Currently, no rate limiting is implemented. This may be added in future versions.

## Versioning

The API uses URL path versioning (`/api/v1/`). Future versions will be available at `/api/v2/`, etc.

## CORS

CORS is not currently configured. This may be added for browser-based applications in future versions.