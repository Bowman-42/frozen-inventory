# Inventory Management System

A modern, multilingual Ruby on Rails web application for managing inventory across multiple storage locations using barcode scanning technology. Originally designed for frozen food management, but configurable for any inventory type including warehouses, retail stores, laboratories, and more.

## 🌟 Features

### 🌐 Multilingual Support
- **4 Languages**: English, Spanish, French, and German
- **Configurable Terminology**: Customize location terms (fridges, warehouses, stores, labs)
- **Dynamic Translations**: Complete interface localization including forms, buttons, and messages
- **Industry Presets**: Pre-configured settings for different business types

### 📊 Inventory Management
- **Dashboard**: Overview of all locations with recent inventory activity
- **Search & Filter**: Find items across all locations with real-time search
- **Category Management**: Organize items with searchable categories
- **Location Management**: Manage multiple storage locations with detailed tracking
- **Barcode Integration**: Unique barcode tracking for items and locations
- **Bulk Operations**: Print multiple barcode labels with quantity selection

### 🕒 Aging & Analytics
- **Storage Duration Tracking**: Monitor how long items have been stored
- **Aging Thresholds**: Configurable warning (120 days) and danger (180 days) levels
- **Visual Indicators**: Color-coded badges showing storage age
- **Oldest Items Report**: Identify items that should be used first
- **Statistics**: Total quantities, storage locations, and aging summaries

### 📱 Mobile API
- **RESTful API**: Complete API for mobile app integration
- **Barcode Scanning**: Add/remove items using location and item barcodes
- **Real-time Updates**: Instant inventory updates across all interfaces
- **Status Monitoring**: Health checks and system status endpoints

### 🎨 User Experience
- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile devices
- **Print Labels**: Generate barcode labels for items and locations
- **Sortable Tables**: Click column headers to sort by name, category, or quantity
- **Empty State Handling**: Helpful guidance when locations or categories are empty
- **Form Validation**: Comprehensive data validation with multilingual error messages

### 🔧 Technical Features
- **Rails 8**: Latest Ruby on Rails framework with Turbo Drive
- **SQLite Database**: Lightweight, serverless database
- **Counter Caching**: Efficient quantity calculations
- **Pagination**: Kaminari gem for handling large inventories
- **CSV Import/Export**: Bulk data management with automatic category creation
- **Configurable Settings**: File-based configuration with industry presets

## 🚀 Quick Start

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

## 🔧 Configuration

### System Settings
Access the configuration page at `/settings` to customize:

- **App Title**: Custom name for your inventory system
- **Location Terms**: Singular/plural terms (e.g., "Fridge/Fridges", "Warehouse/Warehouses")
- **Location Emoji**: Visual identifier for locations
- **Language**: Choose from English, Spanish, French, or German
- **Aging Settings**: Enable tracking with custom thresholds and labels

### Industry Presets
Choose from pre-configured settings:
- **Frozen Food**: Fridges/Freezers with 120/180 day aging thresholds
- **Warehouse**: General warehouse management without aging
- **Retail**: Store inventory with longer aging periods
- **Laboratory**: Lab equipment with short aging thresholds (30/90 days)

### Custom Configuration
Create your own configuration by setting each value individually for maximum flexibility.

## 📖 Usage

### Web Interface

#### Dashboard
- View all locations and recent inventory activity
- Access quick actions: New Item, New Location, All Items, etc.
- Search across all items and locations
- View aging reports (if enabled)

#### Items Management
- **All Items**: Browse, search, and filter items by category
- **Create Items**: Add new items with automatic barcode generation
- **Edit Items**: Update item information and categories
- **Print Labels**: Select multiple items and print quantity-specific labels

#### Categories
- **Category Management**: Create, edit, and delete item categories
- **Statistics**: View total items and quantities per category
- **Filtering**: Filter items by category across the application

#### Locations
- **Location Management**: Create and manage storage locations
- **Contents View**: See all items in each location with aging information
- **Statistics**: Track total items and oldest storage times

#### Aging Reports
- **Oldest Items**: View items sorted by storage duration
- **Aging Thresholds**: See items exceeding warning/danger periods
- **Visual Indicators**: Color-coded badges (fresh, warning, danger)

### Mobile API Integration

The system provides a complete REST API for mobile applications.

#### Quick API Examples

**Check system status:**
```bash
curl http://localhost:3000/api/v1/status
```

**Get location contents:**
```bash
curl http://localhost:3000/api/v1/locations/FRIDGE001
```

**Add item to location:**
```bash
curl -X POST http://localhost:3000/api/v1/add-item \
  -H "Content-Type: application/json" \
  -d '{"location_barcode":"FRIDGE001","item_barcode":"ITEM001","quantity":2}'
```

### CSV Import/Export

#### Import Items
```bash
rails import:items[path/to/items.csv]
rails import:items[path/to/items.csv,dry_run]  # Preview without importing
```

#### Export Items
```bash
rails export:items[path/to/export.csv]
```

**CSV Format:**
```csv
name,category,description,barcode
Frozen Pizza,Frozen Food,Pepperoni pizza,PIZZA001
Milk,Dairy,Whole milk 1L,MILK001
```

## 🗃️ Database Schema

### Core Models

- **Location**: Storage locations (fridges, warehouses, etc.) with unique barcodes
- **Item**: Individual inventory items with unique barcodes and categories
- **InventoryItem**: Junction table tracking quantities, timestamps, and storage duration
- **Category**: Organizational categories for items

### Key Relationships
- Locations have many Items through InventoryItems
- Items can exist in multiple Locations with different quantities
- Items belong to Categories (optional)
- All relationships include proper validations and constraints

## 🛠️ Development

### Running Tests
```bash
rails test
```

### Manage Test Data
```bash
# Create sample data for testing
rails test_data:create

# Create realistic aging data
rails test_data:create_varied_ages

# Clear inventory only (preserve items/locations)
rails inventory:clear
```

### Database Console
```bash
rails console
```

### Reset Database
```bash
rails db:reset
```

### Code Style
The project follows Rails conventions with RuboCop:
```bash
bundle exec rubocop
```

## 🌍 Internationalization

### Supported Languages
- 🇺🇸 **English** (en) - Default
- 🇪🇸 **Spanish** (es) - Español
- 🇫🇷 **French** (fr) - Français
- 🇩🇪 **German** (de) - Deutsch

### Translation Files
Located in `config/locales/`:
- `en.yml` - English translations
- `es.yml` - Spanish translations
- `fr.yml` - French translations
- `de.yml` - German translations

### Adding New Languages
1. Create new locale file in `config/locales/`
2. Add language to `@available_locales` in `SettingsController`
3. Translate all keys following existing structure

## 🚢 Deployment

### Docker
```bash
docker build -t inventory-system .
docker run -p 3000:3000 inventory-system
```

### Kamal (Production)
```bash
kamal setup
kamal deploy
```

### Environment Variables
- `RAILS_ENV`: Environment (development, test, production)
- `SECRET_KEY_BASE`: Rails secret key (auto-generated)
- `DATABASE_URL`: Database connection string (optional)

## 🔒 Security

- CSRF protection enabled for web forms
- SQL injection protection through ActiveRecord
- XSS protection with Rails built-in helpers
- Secrets management with Rails credentials
- Input validation and sanitization

## 🏢 Multi-Tenant Considerations

The application is designed as single-tenant but includes architectural groundwork for multi-tenant expansion:
- Configurable terminology and settings
- Internationalization support
- Modular design patterns
- See `plan.md` for detailed multi-tenant migration strategy

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Contribution Guidelines
- Follow Rails conventions
- Add tests for new features
- Update translations for all supported languages
- Run RuboCop before submitting

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Create an issue in the repository
- Check the application logs in `log/development.log`
- Review the configuration at `/settings`

---

**Built with ❤️ using Ruby on Rails 8**