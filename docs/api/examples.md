# API Usage Examples

This document provides practical examples of using the Frozen Inventory API for common scenarios.

## Setup

All examples assume the server is running at `http://localhost:3000`. Replace with your actual server URL.

## Basic Examples

### 1. System Health Check

Before using the API, verify the system is running:

```bash
curl -X GET http://localhost:3000/api/v1/status
```

**Expected Response:**
```json
{
  "data": {
    "status": "ok",
    "version": "1.0.0",
    "timestamp": "2024-01-15T10:30:00Z",
    "database": {
      "connected": true,
      "locations_count": 3,
      "items_count": 25,
      "inventory_items_count": 45
    }
  }
}
```

### 2. Check What's in a Fridge

View all items in a specific fridge:

```bash
curl -X GET http://localhost:3000/api/v1/locations/FRIDGE001
```

**Response:**
```json
{
  "data": {
    "id": 1,
    "name": "Main Kitchen Fridge",
    "barcode": "FRIDGE001",
    "description": "Main refrigerator in the kitchen",
    "total_items": 8,
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
      }
    ]
  }
}
```

### 3. Find Where an Item is Stored

Locate all fridges containing a specific item:

```bash
curl -X GET http://localhost:3000/api/v1/items/ITEM001
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
          "barcode": "FRIDGE001"
        },
        "quantity": 2,
        "added_at": "2024-01-15T09:00:00Z"
      },
      {
        "location": {
          "id": 2,
          "name": "Basement Freezer",
          "barcode": "FRIDGE002"
        },
        "quantity": 3,
        "added_at": "2024-01-14T15:30:00Z"
      }
    ]
  }
}
```

## Inventory Management Examples

### 4. Add New Items to Inventory

Add 3 frozen pizzas to the basement freezer:

```bash
curl -X POST http://localhost:3000/api/v1/add-item \
  -H "Content-Type: application/json" \
  -d '{
    "location_barcode": "FRIDGE002",
    "item_barcode": "ITEM003",
    "quantity": 3
  }'
```

**Response:**
```json
{
  "data": {
    "inventory_item": {
      "id": 15,
      "quantity": 3,
      "added_at": "2024-01-15T11:00:00Z"
    },
    "location": {
      "id": 2,
      "name": "Basement Freezer",
      "barcode": "FRIDGE002"
    },
    "item": {
      "id": 3,
      "name": "Frozen Pizza",
      "barcode": "ITEM003"
    }
  },
  "message": "Item added successfully"
}
```

### 5. Add More of Existing Items

Add 2 more milk cartons to existing inventory:

```bash
curl -X POST http://localhost:3000/api/v1/add-item \
  -H "Content-Type: application/json" \
  -d '{
    "location_barcode": "FRIDGE001",
    "item_barcode": "ITEM001",
    "quantity": 2
  }'
```

**Response (quantities combined):**
```json
{
  "data": {
    "inventory_item": {
      "id": 1,
      "quantity": 4,
      "added_at": "2024-01-15T09:00:00Z"
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

### 6. Remove Items from Inventory

Remove 1 milk carton:

```bash
curl -X POST http://localhost:3000/api/v1/remove-item \
  -H "Content-Type: application/json" \
  -d '{
    "location_barcode": "FRIDGE001",
    "item_barcode": "ITEM001",
    "quantity": 1
  }'
```

**Response (partial removal):**
```json
{
  "data": {
    "inventory_item": {
      "id": 1,
      "quantity": 3,
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

### 7. Remove All Items of a Type

Remove all remaining milk cartons:

```bash
curl -X POST http://localhost:3000/api/v1/remove-item \
  -H "Content-Type: application/json" \
  -d '{
    "location_barcode": "FRIDGE001",
    "item_barcode": "ITEM001",
    "quantity": 5
  }'
```

**Response (complete removal):**
```json
{
  "data": {
    "message": "Item completely removed from location",
    "removed_quantity": 3,
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

## Mobile App Integration Examples

### 8. Barcode Scanner Workflow

Typical mobile app workflow for adding items:

1. **Scan location barcode** (e.g., QR code on fridge)
2. **Scan item barcode** (e.g., product UPC)
3. **Add to inventory**

```bash
# Step 1: Verify location exists
curl -X GET http://localhost:3000/api/v1/locations/FRIDGE001

# Step 2: Verify item exists
curl -X GET http://localhost:3000/api/v1/items/ITEM001

# Step 3: Add item to location
curl -X POST http://localhost:3000/api/v1/add-item \
  -H "Content-Type: application/json" \
  -d '{
    "location_barcode": "FRIDGE001",
    "item_barcode": "ITEM001",
    "quantity": 1
  }'
```

### 9. Inventory Check Workflow

Check what's running low:

```bash
# Get current status
curl -X GET http://localhost:3000/api/v1/status

# Check each fridge
curl -X GET http://localhost:3000/api/v1/locations/FRIDGE001
curl -X GET http://localhost:3000/api/v1/locations/FRIDGE002
curl -X GET http://localhost:3000/api/v1/locations/FREEZER001
```

## Error Handling Examples

### 10. Invalid Barcode

```bash
curl -X GET http://localhost:3000/api/v1/locations/INVALID
```

**Response (404 Not Found):**
```json
{
  "error": "Record not found",
  "message": "Couldn't find Location with 'barcode'=INVALID"
}
```

### 11. Missing Required Parameters

```bash
curl -X POST http://localhost:3000/api/v1/add-item \
  -H "Content-Type: application/json" \
  -d '{
    "item_barcode": "ITEM001",
    "quantity": 1
  }'
```

**Response (422 Unprocessable Entity):**
```json
{
  "error": "Location barcode is required"
}
```

### 12. Item Not in Location

```bash
curl -X POST http://localhost:3000/api/v1/remove-item \
  -H "Content-Type: application/json" \
  -d '{
    "location_barcode": "FRIDGE001",
    "item_barcode": "NONEXISTENT",
    "quantity": 1
  }'
```

**Response (404 Not Found):**
```json
{
  "error": "Item not found in this location"
}
```

## Advanced Usage

### 13. Bulk Operations

For bulk operations, make multiple API calls:

```bash
# Add multiple items to the same fridge
for item in ITEM001 ITEM002 ITEM003; do
  curl -X POST http://localhost:3000/api/v1/add-item \
    -H "Content-Type: application/json" \
    -d "{\"location_barcode\":\"FRIDGE001\",\"item_barcode\":\"$item\",\"quantity\":1}"
  echo "" # New line for readability
done
```

### 14. Inventory Reporting

Generate inventory reports:

```bash
#!/bin/bash
echo "=== Inventory Report ==="
echo ""

# Get system overview
echo "System Status:"
curl -s http://localhost:3000/api/v1/status | jq '.data.database'
echo ""

# Get each location's contents
for fridge in FRIDGE001 FRIDGE002 FREEZER001; do
  echo "Contents of $fridge:"
  curl -s http://localhost:3000/api/v1/locations/$fridge | jq '.data | {name, total_items}'
  echo ""
done
```

## Testing with Different Tools

### Using HTTPie
```bash
# Install HTTPie: pip install httpie

# Get status
http GET localhost:3000/api/v1/status

# Add item
http POST localhost:3000/api/v1/add-item \
  location_barcode=FRIDGE001 \
  item_barcode=ITEM001 \
  quantity:=2
```

### Using JavaScript (Fetch)
```javascript
// Get status
const response = await fetch('http://localhost:3000/api/v1/status');
const data = await response.json();
console.log(data);

// Add item
const addResponse = await fetch('http://localhost:3000/api/v1/add-item', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    location_barcode: 'FRIDGE001',
    item_barcode: 'ITEM001',
    quantity: 2
  })
});
const addData = await addResponse.json();
console.log(addData);
```

### Using Python Requests
```python
import requests

# Get status
response = requests.get('http://localhost:3000/api/v1/status')
print(response.json())

# Add item
add_response = requests.post('http://localhost:3000/api/v1/add-item',
  json={
    'location_barcode': 'FRIDGE001',
    'item_barcode': 'ITEM001',
    'quantity': 2
  })
print(add_response.json())
```