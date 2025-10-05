# Multi-Tenant Cloud Migration Plan

## Executive Summary

Transform the current single-tenant inventory system into a multi-tenant SaaS platform while maintaining the local hosting option. This plan addresses database architecture, tenant isolation, configuration management, and deployment strategies.

## Current State Analysis

### Strengths
- ✅ Configurable terminology system (per-tenant customization ready)
- ✅ Localization framework (4 languages supported)
- ✅ Modular architecture with clear separation of concerns
- ✅ File-based configuration system
- ✅ RESTful API foundation
- ✅ Modern Rails 8.0 foundation

### Limitations for Multi-Tenancy
- ❌ Single database with no tenant separation
- ❌ Global configuration file (`inventory_settings.yml`)
- ❌ No tenant authentication/authorization
- ❌ No tenant data isolation
- ❌ No billing/subscription management
- ❌ No tenant-specific subdomain/routing

## Multi-Tenant Architecture Options

### Option 1: Shared Database, Shared Schema (Recommended for MVP)
**Database Strategy**: Add `tenant_id` to all tables, filter all queries by tenant

**Pros:**
- Fastest to implement
- Most cost-effective for cloud hosting
- Easy resource sharing
- Simplest backup/maintenance

**Cons:**
- Risk of data leakage if code bugs
- Less customization per tenant
- Shared performance impact

### Option 2: Shared Database, Separate Schemas
**Database Strategy**: Each tenant gets own PostgreSQL schema

**Pros:**
- Better data isolation
- Per-tenant customization possible
- Good performance isolation

**Cons:**
- More complex migrations
- Schema-level management overhead

### Option 3: Separate Databases
**Database Strategy**: Completely separate database per tenant

**Pros:**
- Maximum isolation and security
- Per-tenant backups
- Independent scaling
- Custom schema per tenant

**Cons:**
- Highest infrastructure cost
- Complex connection management
- Migration complexity

## Recommended Implementation Plan

### Phase 1: Foundation (2-3 weeks)

#### 1.1 Tenant Model & Authentication
```ruby
# Models to add:
class Tenant < ApplicationRecord
  has_many :users
  has_many :locations
  has_many :items
  has_many :categories
  has_many :inventory_items

  validates :subdomain, presence: true, uniqueness: true
  validates :name, presence: true
end

class User < ApplicationRecord
  belongs_to :tenant
  # Add authentication (Devise)
end
```

#### 1.2 Database Migration Strategy
```sql
-- Add tenant_id to all existing tables
ALTER TABLE locations ADD COLUMN tenant_id BIGINT;
ALTER TABLE items ADD COLUMN tenant_id BIGINT;
ALTER TABLE categories ADD COLUMN tenant_id BIGINT;
ALTER TABLE inventory_items ADD COLUMN tenant_id BIGINT;

-- Add foreign key constraints
ALTER TABLE locations ADD CONSTRAINT fk_locations_tenant
  FOREIGN KEY (tenant_id) REFERENCES tenants(id);
-- Repeat for all tables

-- Create indexes for performance
CREATE INDEX idx_locations_tenant_id ON locations(tenant_id);
-- Repeat for all tables
```

#### 1.3 Tenant-Scoped Models
```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Global scope for tenant isolation
  scope :for_tenant, ->(tenant) { where(tenant: tenant) }
end

class Location < ApplicationRecord
  belongs_to :tenant

  # Add default scope for tenant isolation
  default_scope -> {
    where(tenant: Current.tenant) if Current.tenant
  }
end
```

#### 1.4 Current Context Management
```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :tenant, :user

  def tenant=(tenant)
    super
    Time.zone = tenant.time_zone if tenant
  end
end

class ApplicationController < ActionController::Base
  before_action :set_current_tenant

  private

  def set_current_tenant
    if subdomain_tenant?
      Current.tenant = Tenant.find_by!(subdomain: request.subdomain)
    elsif params[:tenant_id]
      Current.tenant = Tenant.find(params[:tenant_id])
    end

    # Existing locale setting
    InventoryConfig.load_config_from_file(Current.tenant)
    I18n.locale = InventoryConfig.config.locale || I18n.default_locale
  end
end
```

### Phase 2: Configuration Per Tenant (1-2 weeks)

#### 2.1 Tenant-Specific Configuration
```ruby
class TenantConfiguration < ApplicationRecord
  belongs_to :tenant

  # Store configuration as JSON
  store :settings, accessors: [
    :app_title, :location_singular, :location_plural,
    :location_emoji, :item_context, :locale,
    :aging_enabled, :aging_warning_days, :aging_danger_days
  ]

  def self.for_tenant(tenant)
    find_or_create_by(tenant: tenant)
  end
end

class InventoryConfig
  # Update to support tenant-specific config
  def self.config(tenant = Current.tenant)
    return @default_config unless tenant

    tenant_config = TenantConfiguration.for_tenant(tenant)
    # Merge tenant settings with defaults
  end
end
```

#### 2.2 File Storage Strategy
```ruby
# Move from global YAML to database storage
class TenantConfiguration
  def save_to_database
    # Replace file-based storage with database storage
    self.update!(settings: current_config_hash)
  end

  def load_from_database
    # Load configuration from database instead of file
    self.settings || default_settings
  end
end
```

### Phase 3: Authentication & Subdomain Routing (1-2 weeks)

#### 3.1 Subdomain-Based Tenant Resolution
```ruby
# config/routes.rb
Rails.application.routes.draw do
  constraints subdomain: /.+/ do
    # Tenant-specific routes
    root 'inventory#index'
    resources :locations
    resources :items
    # ... existing routes
  end

  # Admin/signup routes on main domain
  constraints subdomain: false do
    root 'marketing#index'
    resources :tenants, only: [:new, :create]
    namespace :admin do
      resources :tenants
    end
  end
end
```

#### 3.2 User Authentication
```ruby
# Add Devise for user management
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :tenant

  enum role: { member: 0, admin: 1, owner: 2 }
end

class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_current_tenant

  private

  def set_current_tenant
    Current.tenant = current_user&.tenant ||
                    Tenant.find_by(subdomain: request.subdomain)
    redirect_to new_user_session_path unless Current.tenant
  end
end
```

### Phase 4: Cloud Infrastructure (2-3 weeks)

#### 4.1 Database Configuration
```yaml
# config/database.yml
production:
  primary:
    <<: *default
    database: inventory_production
    url: <%= ENV['DATABASE_URL'] %>
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

  # Optional: Separate read replicas for scaling
  primary_replica:
    <<: *default
    database: inventory_production
    url: <%= ENV['DATABASE_REPLICA_URL'] %>
    replica: true
```

#### 4.2 Container Strategy (Docker)
```dockerfile
# Dockerfile
FROM ruby:3.4-slim

WORKDIR /app

# Install dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install --deployment --without development test

# Copy application
COPY . .

# Precompile assets
RUN bundle exec rake assets:precompile

# Expose port
EXPOSE 3000

# Start command
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/inventory
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: inventory
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

#### 4.3 Cloud Deployment Options

**Option A: AWS (Recommended for enterprise)**
- **Compute**: ECS Fargate or EKS
- **Database**: RDS PostgreSQL with Multi-AZ
- **Storage**: S3 for file uploads
- **CDN**: CloudFront
- **Load Balancer**: Application Load Balancer
- **DNS**: Route 53 with wildcard subdomain

**Option B: Heroku (Recommended for quick MVP)**
- **Compute**: Heroku Dynos
- **Database**: Heroku Postgres
- **Storage**: AWS S3 addon
- **CDN**: Heroku CDN
- **DNS**: Heroku DNS with custom domains

**Option C: DigitalOcean (Cost-effective)**
- **Compute**: App Platform or Droplets
- **Database**: Managed PostgreSQL
- **Storage**: Spaces (S3-compatible)
- **CDN**: Built-in CDN
- **Load Balancer**: DigitalOcean Load Balancer

### Phase 5: Billing & Subscription Management (2-3 weeks)

#### 5.1 Subscription Model
```ruby
class Plan < ApplicationRecord
  has_many :tenants

  validates :name, presence: true
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  validates :max_locations, presence: true
  validates :max_items, presence: true

  monetize :price_cents
end

class Tenant < ApplicationRecord
  belongs_to :plan

  validates :stripe_customer_id, presence: true
  validates :subscription_status, inclusion: {
    in: %w[active past_due canceled]
  }

  def within_limits?
    locations.count <= plan.max_locations &&
    items.count <= plan.max_items
  end
end
```

#### 5.2 Usage Enforcement
```ruby
class ApplicationController < ActionController::Base
  before_action :check_subscription_status
  before_action :check_usage_limits

  private

  def check_subscription_status
    return unless Current.tenant

    unless Current.tenant.subscription_active?
      redirect_to billing_path, alert: 'Subscription required'
    end
  end

  def check_usage_limits
    return unless Current.tenant

    unless Current.tenant.within_limits?
      redirect_to upgrade_path, alert: 'Usage limits exceeded'
    end
  end
end
```

### Phase 6: Local Hosting Compatibility (1 week)

#### 6.1 Deployment Modes
```ruby
# config/application.rb
module FrozenInventory
  class Application < Rails::Application
    # Deployment mode configuration
    config.deployment_mode = ENV.fetch('DEPLOYMENT_MODE', 'local') # local, cloud
    config.multi_tenant = ENV.fetch('MULTI_TENANT', 'false') == 'true'
  end
end

# lib/deployment_config.rb
class DeploymentConfig
  def self.local_mode?
    Rails.application.config.deployment_mode == 'local'
  end

  def self.cloud_mode?
    Rails.application.config.deployment_mode == 'cloud'
  end

  def self.multi_tenant?
    Rails.application.config.multi_tenant
  end
end
```

#### 6.2 Local Mode Adaptations
```ruby
class ApplicationController < ActionController::Base
  before_action :set_current_tenant

  private

  def set_current_tenant
    if DeploymentConfig.local_mode?
      # Local mode: single tenant or file-based config
      Current.tenant = Tenant.first || create_default_tenant
    else
      # Cloud mode: subdomain-based tenant resolution
      Current.tenant = Tenant.find_by!(subdomain: request.subdomain)
    end
  end

  def create_default_tenant
    Tenant.create!(
      name: 'Local Installation',
      subdomain: 'local'
    )
  end
end
```

### Phase 7: Migration Strategy (1-2 weeks)

#### 7.1 Data Migration Script
```ruby
# lib/tasks/migrate_to_multi_tenant.rake
namespace :multi_tenant do
  desc "Migrate existing single-tenant data to multi-tenant structure"
  task :migrate_data => :environment do
    # Create default tenant
    default_tenant = Tenant.create!(
      name: ENV.fetch('TENANT_NAME', 'Default Tenant'),
      subdomain: ENV.fetch('SUBDOMAIN', 'main')
    )

    # Migrate existing data
    puts "Migrating locations..."
    Location.update_all(tenant_id: default_tenant.id)

    puts "Migrating items..."
    Item.update_all(tenant_id: default_tenant.id)

    puts "Migrating categories..."
    Category.update_all(tenant_id: default_tenant.id)

    puts "Migrating inventory items..."
    InventoryItem.update_all(tenant_id: default_tenant.id)

    # Migrate configuration
    puts "Migrating configuration..."
    migrate_configuration_to_tenant(default_tenant)

    puts "Migration complete!"
  end

  private

  def migrate_configuration_to_tenant(tenant)
    config_file = Rails.root.join('config', 'inventory_settings.yml')
    if File.exist?(config_file)
      settings = YAML.load_file(config_file)
      TenantConfiguration.create!(
        tenant: tenant,
        settings: settings
      )
    end
  end
end
```

#### 7.2 Rollback Strategy
```ruby
namespace :multi_tenant do
  desc "Rollback to single-tenant mode"
  task :rollback => :environment do
    # Extract configuration back to file
    default_tenant = Tenant.find_by(subdomain: 'main')
    if default_tenant&.configuration
      config_file = Rails.root.join('config', 'inventory_settings.yml')
      File.write(config_file, default_tenant.configuration.settings.to_yaml)
    end

    # Remove tenant_id columns would require separate migration
    puts "Configuration extracted. Run migration to remove tenant_id columns."
  end
end
```

## Cloud Deployment Checklist

### Pre-Deployment
- [ ] Environment variables configured
- [ ] Database migrations tested
- [ ] SSL certificates configured
- [ ] DNS wildcard setup (*.yourdomain.com)
- [ ] Backup strategy implemented
- [ ] Monitoring tools configured

### Security Considerations
- [ ] Tenant data isolation verified
- [ ] SQL injection prevention tested
- [ ] Cross-tenant access prevention
- [ ] Secrets management (AWS Secrets Manager/Vault)
- [ ] GDPR compliance measures
- [ ] Data encryption at rest and in transit

### Performance Considerations
- [ ] Database indexing for tenant_id
- [ ] Connection pooling configured
- [ ] Redis caching for configurations
- [ ] CDN for static assets
- [ ] Database query optimization

### Monitoring & Maintenance
- [ ] Application monitoring (NewRelic/DataDog)
- [ ] Database monitoring
- [ ] Error tracking (Bugsnag/Sentry)
- [ ] Log aggregation (ELK stack)
- [ ] Automated backups
- [ ] Health checks

## Cost Estimation (Monthly)

### MVP Cloud Deployment (Heroku)
- **Heroku Dyno (Production)**: $25/month
- **Heroku Postgres (Standard-0)**: $50/month
- **Redis addon**: $15/month
- **Total**: ~$90/month for up to 100 tenants

### Enterprise Cloud Deployment (AWS)
- **ECS Fargate (2 tasks)**: $50/month
- **RDS PostgreSQL (db.t3.small)**: $25/month
- **Application Load Balancer**: $20/month
- **S3 Storage**: $5/month
- **CloudFront CDN**: $10/month
- **Total**: ~$110/month + scaling costs

### Local Deployment
- **No monthly costs**
- **One-time setup**: 2-4 hours
- **Hardware requirements**: 2GB RAM, 10GB storage

## Timeline Summary

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| Phase 1 | 2-3 weeks | Tenant model, database schema, basic isolation |
| Phase 2 | 1-2 weeks | Per-tenant configuration system |
| Phase 3 | 1-2 weeks | Authentication, subdomain routing |
| Phase 4 | 2-3 weeks | Cloud infrastructure, containerization |
| Phase 5 | 2-3 weeks | Billing, subscription management |
| Phase 6 | 1 week | Local hosting compatibility |
| Phase 7 | 1-2 weeks | Migration tools, testing |

**Total**: 10-16 weeks for full implementation

## Risk Mitigation

### Technical Risks
- **Data leakage**: Comprehensive test suite for tenant isolation
- **Performance**: Database query optimization and monitoring
- **Complexity**: Phased rollout with rollback procedures

### Business Risks
- **Customer disruption**: Maintain local hosting option
- **Cost overruns**: Start with MVP on cost-effective platform
- **Feature regression**: Comprehensive test coverage

## Success Metrics

- **Technical**: 99.9% uptime, <200ms response times
- **Business**: Support 1000+ tenants, 10x cost efficiency
- **User Experience**: Zero downtime migrations, preserved functionality

## Conclusion

This plan provides a comprehensive path to multi-tenancy while preserving the flexibility of local hosting. The phased approach minimizes risk and allows for iterative improvements. The shared database, shared schema approach offers the best balance of implementation speed, cost-effectiveness, and scalability for most use cases.