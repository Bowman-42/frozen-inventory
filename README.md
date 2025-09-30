# Frozen Inventory Management System

A modern Ruby on Rails web application for managing frozen food inventory across multiple refrigerators and freezers using barcode scanning technology.

## Features

### 🌐 Web Interface
- **Dashboard**: Overview of all fridges with recent inventory activity
- **Search & Filter**: Find items across all locations with real-time search
- **Inventory Management**: View detailed contents of each fridge/freezer
- **Item & Location Creation**: Add new items and fridges through web forms
- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile devices

### 📱 Mobile API
- **RESTful API**: Complete API for mobile app integration
- **Barcode Scanning**: Add/remove items using location and item barcodes
- **Real-time Updates**: Instant inventory updates across all interfaces
- **Status Monitoring**: Health checks and system status endpoints

### 🔧 Technical Features
- **Rails 8**: Latest Ruby on Rails framework
- **SQLite Database**: Lightweight, serverless database
- **Barcode Integration**: Unique barcode tracking for items and locations
- **Pagination**: Efficient handling of large inventories
- **Validation**: Comprehensive data validation and error handling

## Quick Start

### Prerequisites
- Ruby 3.4+
- Rails 8.0+
- SQLite3

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd frozen-inventory
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Setup database**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed  # Optional: Creates sample data
   ```

4. **Start the server**
   ```bash
   rails server
   ```

5. **Open your browser**
   ```
   http://localhost:3000
   ```

## Usage

### Web Interface

#### Dashboard
- Access the main dashboard at `/`
- View all fridges and recent inventory activity
- Use action buttons to create new items or fridges

#### Creating Items
1. Click "📦 New Item" from the dashboard
2. Fill in the form with item name, barcode, and description
3. Submit to create the item

#### Creating Fridges/Locations
1. Click "➕ New Fridge" from the dashboard
2. Enter fridge name, barcode, and description
3. Submit to create the location

#### Searching
- Use the search bar on the dashboard
- Search across item names, barcodes, and location names
- Results are paginated for performance

### Mobile API Integration

The system provides a complete REST API for mobile applications. See [API Documentation](docs/api/README.md) for detailed endpoint information.

#### Quick API Examples

**Check system status:**
```bash
curl http://localhost:3000/api/v1/status
```

**Get fridge contents:**
```bash
curl http://localhost:3000/api/v1/locations/FRIDGE001
```

**Add item to fridge:**
```bash
curl -X POST http://localhost:3000/api/v1/add-item \
  -H "Content-Type: application/json" \
  -d '{"location_barcode":"FRIDGE001","item_barcode":"ITEM001","quantity":2}'
```

## Database Schema

### Core Models

- **Location**: Represents fridges/freezers with unique barcodes
- **Item**: Individual inventory items with unique barcodes
- **InventoryItem**: Join table tracking quantities and timestamps

### Key Relationships
- Locations have many Items through InventoryItems
- Items can exist in multiple Locations with different quantities
- All relationships include proper validations and constraints

## Development

### Running Tests
```bash
rails test
```

### Code Style
The project uses RuboCop for code styling:
```bash
bundle exec rubocop
```

### Database Console
```bash
rails console
```

### Reset Database
```bash
rails db:reset
```

## Deployment

The application includes Docker and Kamal configuration for easy deployment:

### Docker
```bash
docker build -t frozen-inventory .
docker run -p 3000:3000 frozen-inventory
```

### Kamal (Production)
```bash
kamal setup
kamal deploy
```

For detailed deployment instructions, see the [Deployment Guide](docs/DEPLOYMENT.md).

## API Documentation

Comprehensive API documentation is available in the `docs/api/` directory:

- [API Overview](docs/api/README.md)
- [Endpoints Reference](docs/api/endpoints.md)
- [Error Handling](docs/api/errors.md)
- [Examples](docs/api/examples.md)
- [Mobile Integration Guide](docs/api/mobile-integration.md)

## Configuration

### Environment Variables
- `RAILS_ENV`: Environment (development, test, production)
- `SECRET_KEY_BASE`: Rails secret key (auto-generated)
- `DATABASE_URL`: Database connection string (optional)

### Database Configuration
SQLite is used by default. Configuration is in `config/database.yml`.

## Security

- CSRF protection enabled for web forms
- SQL injection protection through ActiveRecord
- XSS protection with Rails built-in helpers
- Secrets management with Rails credentials

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Check the [API documentation](docs/api/README.md)
- Review the application logs in `log/development.log`
