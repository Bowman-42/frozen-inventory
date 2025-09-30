# Frozen Inventory API Documentation

The Frozen Inventory system provides a comprehensive REST API for mobile applications and third-party integrations. The API is designed for barcode-based inventory management across multiple refrigerator/freezer locations.

## Base URL

```
http://localhost:3000/api/v1
```

## Authentication

Currently, the API does not require authentication. This may be added in future versions.

## Content Type

All API endpoints accept and return JSON:

```
Content-Type: application/json
```

## Response Format

All API responses follow a consistent format:

### Success Response
```json
{
  "data": {
    // Response data
  },
  "message": "Optional success message"
}
```

### Error Response
```json
{
  "error": "Error description",
  "message": "Detailed error message"
}
```

## Endpoints Overview

### System Status
- `GET /api/v1/status` - Get system health and statistics

### Location Management
- `GET /api/v1/locations/{barcode}` - Get location details and contents

### Item Management
- `GET /api/v1/items/{barcode}` - Get item details and locations

### Inventory Operations
- `POST /api/v1/add-item` - Add items to inventory
- `POST /api/v1/remove-item` - Remove items from inventory

## Quick Start Examples

### 1. Check System Status
```bash
curl -X GET http://localhost:3000/api/v1/status
```

### 2. Get Location Contents
```bash
curl -X GET http://localhost:3000/api/v1/locations/FRIDGE001
```

### 3. Add Item to Inventory
```bash
curl -X POST http://localhost:3000/api/v1/add-item \
  -H "Content-Type: application/json" \
  -d '{
    "location_barcode": "FRIDGE001",
    "item_barcode": "ITEM001",
    "quantity": 2
  }'
```

### 4. Remove Item from Inventory
```bash
curl -X POST http://localhost:3000/api/v1/remove-item \
  -H "Content-Type: application/json" \
  -d '{
    "location_barcode": "FRIDGE001",
    "item_barcode": "ITEM001",
    "quantity": 1
  }'
```

## Barcode Requirements

- **Location Barcodes**: Must be unique across all locations (e.g., "FRIDGE001", "FREEZER_BASEMENT")
- **Item Barcodes**: Must be unique across all items (e.g., "ITEM001", "UPC_123456789")
- **Format**: Alphanumeric strings, no special characters except underscores and hyphens

## Error Handling

The API uses standard HTTP status codes:

- `200 OK` - Success
- `404 Not Found` - Resource not found (invalid barcode)
- `422 Unprocessable Entity` - Validation errors
- `500 Internal Server Error` - Server error

See [Error Handling Guide](errors.md) for detailed error scenarios.

## Rate Limiting

Currently, no rate limiting is implemented. This may be added in future versions.

## Detailed Documentation

- [Endpoints Reference](endpoints.md) - Complete endpoint documentation
- [Error Handling](errors.md) - Error codes and troubleshooting
- [Examples](examples.md) - Complete usage examples
- [Mobile Integration](mobile-integration.md) - Mobile app integration guide

## Testing the API

### Using curl
All examples in this documentation use curl for testing. Replace `localhost:3000` with your actual server URL.

### Using Postman
Import the API collection: [Download Postman Collection](postman_collection.json)

### Using HTTPie
```bash
# Install HTTPie
pip install httpie

# Example usage
http GET localhost:3000/api/v1/status
```

## Version History

- **v1.0** - Initial API release with core functionality
  - Location lookup
  - Item lookup
  - Add/remove inventory operations
  - System status endpoint

## Support

For API support:
- Check the [Examples](examples.md) for common use cases
- Review [Error Handling](errors.md) for troubleshooting
- Create an issue in the main repository
- Check server logs for detailed error information