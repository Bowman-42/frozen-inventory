# API Error Handling

This document describes the error handling mechanisms in the Frozen Inventory API.

## HTTP Status Codes

The API uses standard HTTP status codes to indicate the success or failure of requests:

### Success Codes
- `200 OK` - Request successful
- `201 Created` - Resource created successfully (future use)

### Client Error Codes
- `400 Bad Request` - Invalid request format
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation errors

### Server Error Codes
- `500 Internal Server Error` - Unexpected server error

## Error Response Format

All error responses follow a consistent JSON format:

```json
{
  "error": "Brief error description",
  "message": "Detailed error message (optional)"
}
```

## Common Errors

### 1. Resource Not Found (404)

**Scenario**: Invalid barcode provided

```bash
curl -X GET http://localhost:3000/api/v1/locations/INVALID_BARCODE
```

**Response:**
```json
{
  "error": "Record not found",
  "message": "Couldn't find Location with 'barcode'=INVALID_BARCODE"
}
```

**Causes:**
- Location barcode doesn't exist in the database
- Item barcode doesn't exist in the database
- Typo in barcode parameter

**Solutions:**
- Verify barcode spelling and format
- Check if the resource exists through the web interface
- Use the system status endpoint to see available resources

### 2. Validation Errors (422)

#### Missing Required Parameters

**Scenario**: Missing location_barcode in add-item request

```bash
curl -X POST http://localhost:3000/api/v1/add-item \
  -H "Content-Type: application/json" \
  -d '{"item_barcode": "ITEM001", "quantity": 1}'
```

**Response:**
```json
{
  "error": "Location barcode is required"
}
```

#### Missing Item Barcode

```bash
curl -X POST http://localhost:3000/api/v1/add-item \
  -H "Content-Type: application/json" \
  -d '{"location_barcode": "FRIDGE001", "quantity": 1}'
```

**Response:**
```json
{
  "error": "Item barcode is required"
}
```

#### Invalid Quantity

```bash
curl -X POST http://localhost:3000/api/v1/add-item \
  -H "Content-Type: application/json" \
  -d '{"location_barcode": "FRIDGE001", "item_barcode": "ITEM001", "quantity": 0}'
```

**Response:**
```json
{
  "error": "Quantity must be greater than 0"
}
```

**Solutions:**
- Ensure all required parameters are provided
- Validate quantity values before sending
- Check parameter spelling and format

### 3. Item Not in Location (422)

**Scenario**: Trying to remove an item that's not in the specified location

```bash
curl -X POST http://localhost:3000/api/v1/remove-item \
  -H "Content-Type: application/json" \
  -d '{"location_barcode": "FRIDGE001", "item_barcode": "ITEM999", "quantity": 1}'
```

**Response:**
```json
{
  "error": "Item not found in this location"
}
```

**Solutions:**
- Check if the item exists in that location first
- Use GET `/api/v1/locations/{barcode}` to see current contents
- Use GET `/api/v1/items/{barcode}` to see where the item is located

### 4. Server Errors (500)

**Scenario**: Database connection issues or unexpected errors

**Response:**
```json
{
  "error": "Internal server error occurred"
}
```

**Common Causes:**
- Database connectivity issues
- Unexpected application errors
- Server configuration problems

**Solutions:**
- Check server logs for detailed error information
- Verify database is running and accessible
- Contact system administrator

## Error Troubleshooting Guide

### Step 1: Check System Status

Before troubleshooting specific errors, verify the system is healthy:

```bash
curl -X GET http://localhost:3000/api/v1/status
```

If this returns an error, the problem is likely system-wide.

### Step 2: Verify Resource Existence

For barcode-related errors:

```bash
# Check if location exists
curl -X GET http://localhost:3000/api/v1/locations/FRIDGE001

# Check if item exists
curl -X GET http://localhost:3000/api/v1/items/ITEM001
```

### Step 3: Validate Request Format

Ensure your request follows the correct format:

- Content-Type header is set to `application/json`
- JSON is properly formatted
- Required parameters are included
- Parameter names match documentation exactly

### Step 4: Check Server Logs

For persistent issues, check the application logs:

```bash
# Development environment
tail -f log/development.log

# Production environment
tail -f log/production.log
```

## Best Practices for Error Handling

### 1. Implement Retry Logic

For temporary errors (500 status codes):

```python
import requests
import time

def api_request_with_retry(url, data=None, max_retries=3):
    for attempt in range(max_retries):
        try:
            if data:
                response = requests.post(url, json=data)
            else:
                response = requests.get(url)

            if response.status_code == 200:
                return response.json()
            elif response.status_code == 500 and attempt < max_retries - 1:
                time.sleep(2 ** attempt)  # Exponential backoff
                continue
            else:
                return response.json()

        except requests.exceptions.RequestException:
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)
            else:
                raise
```

### 2. Validate Input Before Sending

```javascript
function validateAddItemRequest(locationBarcode, itemBarcode, quantity) {
    const errors = [];

    if (!locationBarcode || locationBarcode.trim() === '') {
        errors.push('Location barcode is required');
    }

    if (!itemBarcode || itemBarcode.trim() === '') {
        errors.push('Item barcode is required');
    }

    if (quantity <= 0) {
        errors.push('Quantity must be greater than 0');
    }

    return errors;
}
```

### 3. Handle Errors Gracefully

```javascript
async function addItem(locationBarcode, itemBarcode, quantity) {
    try {
        const response = await fetch('/api/v1/add-item', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                location_barcode: locationBarcode,
                item_barcode: itemBarcode,
                quantity: quantity
            })
        });

        const data = await response.json();

        if (response.ok) {
            console.log('Item added successfully:', data.message);
            return data;
        } else {
            console.error('API Error:', data.error);
            throw new Error(data.error);
        }
    } catch (error) {
        console.error('Network or parsing error:', error);
        throw error;
    }
}
```

### 4. User-Friendly Error Messages

Map API errors to user-friendly messages:

```javascript
const ERROR_MESSAGES = {
    'Record not found': 'The barcode was not found. Please check and try again.',
    'Location barcode is required': 'Please scan or enter a location barcode.',
    'Item barcode is required': 'Please scan or enter an item barcode.',
    'Quantity must be greater than 0': 'Please enter a valid quantity.',
    'Item not found in this location': 'This item is not currently stored in this location.',
    'Internal server error occurred': 'Something went wrong. Please try again later.'
};

function getUserFriendlyMessage(apiError) {
    return ERROR_MESSAGES[apiError] || 'An unexpected error occurred.';
}
```

## Monitoring and Logging

### Application Logs

The application logs all API requests and errors. Log entries include:

- Request method and path
- Request parameters
- Response status code
- Error details (for failed requests)
- Processing time

### Health Monitoring

Use the status endpoint for health monitoring:

```bash
# Check every 30 seconds
watch -n 30 'curl -s http://localhost:3000/api/v1/status | jq .data.database.connected'
```

### Error Alerting

Set up alerts for common error patterns:

```bash
# Alert on high error rates
tail -f log/production.log | grep "Completed 500" | while read line; do
    echo "Server error detected: $line"
    # Send alert (email, Slack, etc.)
done
```

## Recovery Procedures

### Database Issues

If database errors occur:

1. Check database connectivity
2. Verify sufficient disk space
3. Restart the database service if needed
4. Check for corrupted database files

### Application Errors

For application-level errors:

1. Check application logs
2. Restart the Rails application
3. Verify all dependencies are available
4. Check system resources (memory, CPU)

## Getting Help

If you encounter persistent errors:

1. Check this error documentation
2. Review the API examples in [examples.md](examples.md)
3. Check the main application logs
4. Create an issue in the repository with:
   - Full error message
   - Request details
   - Expected behavior
   - Steps to reproduce