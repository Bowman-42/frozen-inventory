# Individual Item Tracking Implementation Plan

**Date:** October 13, 2024
**Feature:** Individual Item Tracking with API Compatibility
**Status:** Planning Phase
**Estimated Duration:** 2-3 weeks

## Executive Summary

Transform the current quantity-based inventory system into individual item tracking while maintaining 100% API compatibility. This enables accurate FIFO (First-In-First-Out) inventory rotation and precise storage time tracking without requiring any changes to existing clients or item relabeling.

## Problem Statement

The current system aggregates items into quantity counters, making accurate inventory rotation impossible:
- Storage time information becomes inaccurate quickly
- No way to implement proper FIFO/LIFO removal strategies
- Can't track individual item storage duration
- Food safety compliance concerns with old items staying in system

## Solution Overview

Implement a dual-layer architecture:
- **Public Layer**: Maintain existing `InventoryItem` API for compatibility
- **Private Layer**: Add individual item tracking underneath for accuracy

### Key Features
- Counter-based individual barcodes with reuse pool
- Perfect FIFO tracking with exact storage times
- Zero API breaking changes
- Preserve existing item barcodes (no relabeling needed)
- Scalable barcode management system

## Implementation Phases

### Phase 1: Database Schema Enhancement (Week 1)

#### 1.1 Create New Tables

**Migration File:** `db/migrate/YYYYMMDDHHMMSS_create_individual_tracking_infrastructure.rb`

```ruby
class CreateIndividualTrackingInfrastructure < ActiveRecord::Migration[8.0]
  def up
    # Counter management for sequential barcode generation
    create_table :item_id_counters do |t|
      t.references :item, null: false, foreign_key: true
      t.integer :last_counter, default: 0, null: false
      t.timestamps
    end
    add_index :item_id_counters, :item_id, unique: true

    # Barcode pool for reuse management
    create_table :reusable_barcodes do |t|
      t.references :item, null: false, foreign_key: true
      t.string :barcode, null: false
      t.boolean :in_use, default: false, null: false
      t.datetime :created_at, null: false
      t.datetime :last_used_at
    end
    add_index :reusable_barcodes, [:item_id, :in_use]
    add_index :reusable_barcodes, :barcode, unique: true

    # Individual item tracking (core table)
    create_table :individual_inventory_items do |t|
      t.references :location, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.references :reusable_barcode, null: false, foreign_key: true
      t.references :inventory_item, null: false, foreign_key: true
      t.integer :sequence_number, null: false
      t.datetime :added_at, null: false
      t.text :notes # Optional: condition, batch info, etc.
      t.timestamps
    end

    # Optimized indexes for common queries
    add_index :individual_inventory_items, :added_at
    add_index :individual_inventory_items, [:location_id, :item_id]
    add_index :individual_inventory_items, [:item_id, :sequence_number], unique: true
    add_index :individual_inventory_items, :inventory_item_id
  end

  def down
    drop_table :individual_inventory_items
    drop_table :reusable_barcodes
    drop_table :item_id_counters
  end
end
```

#### 1.2 Run Schema Migration

```bash
bin/rails db:migrate
```

**Validation Steps:**
- [ ] All tables created successfully
- [ ] Indexes are in place
- [ ] Foreign key constraints work
- [ ] Database performance is acceptable

### Phase 2: Model Implementation (Week 1-2)

#### 2.1 Create Supporting Models

**File:** `app/models/item_id_counter.rb`
```ruby
class ItemIdCounter < ApplicationRecord
  belongs_to :item

  validates :last_counter, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def self.next_for_item(item)
    counter_record = find_or_create_by(item: item)
    counter_record.with_lock do
      counter_record.increment!(:last_counter)
      counter_record.last_counter
    end
  end
end
```

**File:** `app/models/reusable_barcode.rb`
```ruby
class ReusableBarcode < ApplicationRecord
  belongs_to :item
  has_one :individual_inventory_item, dependent: :nullify

  validates :barcode, presence: true, uniqueness: true

  scope :available, -> { where(in_use: false) }
  scope :in_use, -> { where(in_use: true) }
  scope :legacy, -> { joins(:item).where('reusable_barcodes.barcode = items.barcode') }
  scope :generated, -> { joins(:item).where('reusable_barcodes.barcode != items.barcode') }

  def self.get_available_for_item(item)
    transaction do
      # Try to reuse an available barcode
      barcode = available.where(item: item).first

      if barcode
        barcode.update!(in_use: true, last_used_at: Time.current)
        return barcode
      end

      # Create new barcode with next sequence
      sequence = ItemIdCounter.next_for_item(item)
      create!(
        item: item,
        barcode: generate_barcode_for_item(item, sequence),
        in_use: true,
        last_used_at: Time.current
      )
    end
  end

  def release!
    update!(in_use: false, last_used_at: Time.current)
  end

  def legacy_barcode?
    barcode == item.barcode
  end

  # Pool management methods
  def self.pool_stats_for_item(item)
    {
      total_barcodes: where(item: item).count,
      in_use: in_use.where(item: item).count,
      available: available.where(item: item).count,
      utilization_rate: (in_use.where(item: item).count.to_f / where(item: item).count * 100).round(1)
    }
  end

  def self.ensure_pool_size(item, target_size = 50)
    current_count = where(item: item).count
    return if current_count >= target_size

    needed = target_size - current_count
    barcodes_to_create = []

    needed.times do
      sequence = ItemIdCounter.next_for_item(item)
      barcodes_to_create << {
        item: item,
        barcode: generate_barcode_for_item(item, sequence),
        in_use: false,
        created_at: Time.current
      }
    end

    insert_all(barcodes_to_create)
  end

private

  def self.generate_barcode_for_item(item, sequence)
    "#{item.barcode}-#{sequence.to_s.rjust(5, '0')}"
  end
end
```

**File:** `app/models/individual_inventory_item.rb`
```ruby
class IndividualInventoryItem < ApplicationRecord
  belongs_to :location
  belongs_to :item
  belongs_to :reusable_barcode
  belongs_to :inventory_item

  validates :sequence_number, presence: true, uniqueness: { scope: :item_id }
  validates :added_at, presence: true

  before_create :assign_barcode_and_sequence
  after_destroy :release_barcode

  scope :oldest_first, -> { order(:added_at) }
  scope :newest_first, -> { order(added_at: :desc) }
  scope :by_location_and_item, ->(loc, itm) { where(location: loc, item: itm) }

  def storage_days
    (Time.current - added_at) / 1.day
  end

  def individual_barcode
    reusable_barcode.barcode
  end

private

  def assign_barcode_and_sequence
    self.reusable_barcode = ReusableBarcode.get_available_for_item(item)
    self.sequence_number = ItemIdCounter.next_for_item(item)
    self.added_at ||= Time.current
  end

  def release_barcode
    reusable_barcode&.release!
  end
end
```

#### 2.2 Enhance Existing InventoryItem Model

**File:** `app/models/inventory_item.rb` (Enhanced)
```ruby
class InventoryItem < ApplicationRecord
  belongs_to :location
  belongs_to :item
  has_many :individual_inventory_items, dependent: :destroy

  validates :added_at, presence: true

  before_validation :set_added_at, on: :create
  after_create :update_item_total_quantity
  after_update :update_item_total_quantity, if: :saved_change_to_quantity?
  after_destroy :update_item_total_quantity

  # Individual item management methods
  def add_individual_item!
    individual_item = IndividualInventoryItem.create!(
      location: location,
      item: item,
      inventory_item: self
    )

    # Update aggregated quantity and added_at
    update_aggregate_fields

    individual_item
  end

  def remove_individual_item!(strategy: :fifo, target: nil)
    individual_item = if target
      target
    else
      case strategy
      when :fifo
        individual_inventory_items.oldest_first.first
      when :lifo
        individual_inventory_items.newest_first.first
      else
        raise ArgumentError, "Unknown strategy: #{strategy}"
      end
    end

    return nil unless individual_item

    removed_item_info = {
      individual_barcode: individual_item.individual_barcode,
      sequence_number: individual_item.sequence_number,
      added_at: individual_item.added_at,
      storage_days: individual_item.storage_days
    }

    individual_item.destroy!

    # Update aggregated fields or destroy if empty
    if individual_inventory_items.count == 0
      destroy!
      removed_item_info.merge(completely_removed: true)
    else
      update_aggregate_fields
      removed_item_info.merge(completely_removed: false)
    end
  end

  # API compatibility methods
  def quantity
    individual_inventory_items.count
  end

  def added_at
    individual_inventory_items.minimum(:added_at) || super
  end

private

  def update_aggregate_fields
    oldest_item = individual_inventory_items.oldest_first.first
    update_columns(
      added_at: oldest_item&.added_at || Time.current
    )
  end

  def set_added_at
    self.added_at ||= Time.current
  end

  def update_item_total_quantity
    return unless item
    total = item.inventory_items.sum { |inv_item| inv_item.individual_inventory_items.count }
    item.update_column(:total_quantity, total)
  end
end
```

**Testing Requirements:**
- [ ] Unit tests for all new models
- [ ] Integration tests for barcode management
- [ ] Performance tests for counter generation
- [ ] Validation tests for unique constraints

### Phase 3: Data Migration (Week 2)

#### 3.1 Create Migration for Existing Data

**Migration File:** `db/migrate/YYYYMMDDHHMMSS_migrate_existing_inventory_to_individual_tracking.rb`

```ruby
class MigrateExistingInventoryToIndividualTracking < ActiveRecord::Migration[8.0]
  def up
    puts "Starting migration of existing inventory to individual tracking..."

    migrated_count = 0
    InventoryItem.includes(:item, :location).find_each do |inventory_item|
      next if inventory_item.quantity <= 0

      if inventory_item.quantity == 1
        # Single items: preserve original barcode
        migrate_single_item_preserve_barcode(inventory_item)
        puts "✓ Preserved barcode #{inventory_item.item.barcode} for #{inventory_item.item.name}"
      else
        # Multiple items: create new individual barcodes
        migrate_multiple_items_new_barcodes(inventory_item)
        puts "✓ Created #{inventory_item.quantity} individual barcodes for #{inventory_item.item.name}"
      end

      migrated_count += 1
    end

    puts "Migration completed: #{migrated_count} inventory items migrated"

    # Validate migration
    validate_migration
  end

  def down
    puts "Rolling back individual tracking migration..."
    IndividualInventoryItem.destroy_all
    ReusableBarcode.destroy_all
    ItemIdCounter.destroy_all
    puts "Rollback completed"
  end

private

  def migrate_single_item_preserve_barcode(inventory_item)
    item = inventory_item.item

    # Create reusable barcode using existing item barcode
    reusable_barcode = ReusableBarcode.create!(
      item: item,
      barcode: item.barcode,
      in_use: true,
      last_used_at: inventory_item.added_at,
      created_at: inventory_item.added_at
    )

    # Create individual inventory item
    IndividualInventoryItem.create!(
      location: inventory_item.location,
      item: item,
      inventory_item: inventory_item,
      reusable_barcode: reusable_barcode,
      sequence_number: 1,
      added_at: inventory_item.added_at
    )

    # Initialize counter starting from 2
    ItemIdCounter.create!(
      item: item,
      last_counter: 1
    )
  end

  def migrate_multiple_items_new_barcodes(inventory_item)
    item = inventory_item.item
    counter = ItemIdCounter.find_or_create_by(item: item)

    inventory_item.quantity.times do |i|
      sequence_number = counter.increment!(:last_counter)
      individual_barcode = "#{item.barcode}-#{sequence_number.to_s.rjust(5, '0')}"

      reusable_barcode = ReusableBarcode.create!(
        item: item,
        barcode: individual_barcode,
        in_use: true,
        last_used_at: inventory_item.added_at + i.minutes,
        created_at: inventory_item.added_at
      )

      IndividualInventoryItem.create!(
        location: inventory_item.location,
        item: item,
        inventory_item: inventory_item,
        reusable_barcode: reusable_barcode,
        sequence_number: sequence_number,
        added_at: inventory_item.added_at + i.minutes
      )
    end
  end

  def validate_migration
    puts "Validating migration..."

    # Check that total quantities match
    Item.find_each do |item|
      old_total = item.inventory_items.sum(:quantity)
      new_total = item.individual_inventory_items.count

      unless old_total == new_total
        raise "Migration validation failed for #{item.name}: old_total=#{old_total}, new_total=#{new_total}"
      end
    end

    # Check that all individual items have valid barcodes
    invalid_count = IndividualInventoryItem.joins(:reusable_barcode)
      .where(reusable_barcodes: { in_use: false }).count

    if invalid_count > 0
      raise "Migration validation failed: #{invalid_count} individual items have unused barcodes"
    end

    puts "✓ Migration validation passed"
  end
end
```

#### 3.2 Run Data Migration

```bash
bin/rails db:migrate
```

**Validation Steps:**
- [ ] All existing inventory items migrated correctly
- [ ] Single items preserve original barcodes
- [ ] Multiple items get sequential individual barcodes
- [ ] Total quantities match pre-migration
- [ ] No orphaned records

### Phase 4: Controller Enhancement (Week 2)

#### 4.1 Update Inventory Controller

**File:** `app/controllers/api/v1/inventory_controller.rb` (Enhanced methods)

#### 4.2 Update Barcode Printing Controller

**File:** `app/controllers/items_controller.rb` (Enhanced print_barcodes method)

```ruby
class Api::V1::InventoryController < Api::V1::BaseController
  def add_item
    location_barcode = params[:location_barcode]
    item_barcode = params[:item_barcode]
    quantity = 1

    return render_error('Location barcode is required') if location_barcode.blank?
    return render_error('Item barcode is required') if item_barcode.blank?

    location = Location.find_by(barcode: location_barcode)
    return render_error('Location not found') unless location

    item = Item.find_by(barcode: item_barcode)
    return render_error('Item not found') unless item

    inventory_item = InventoryItem.find_by(location: location, item: item)

    ActiveRecord::Base.transaction do
      if inventory_item
        individual_item = inventory_item.add_individual_item!
      else
        inventory_item = InventoryItem.create!(
          location: location,
          item: item,
          added_at: Time.current
        )
        individual_item = inventory_item.add_individual_item!
      end

      # Enhanced response with individual item info
      response_data = {
        inventory_item: {
          id: inventory_item.id,
          quantity: inventory_item.quantity,
          added_at: inventory_item.added_at.iso8601
        },
        individual_item: {
          individual_barcode: individual_item.individual_barcode,
          is_legacy_barcode: individual_item.reusable_barcode.legacy_barcode?,
          sequence_number: individual_item.sequence_number
        },
        location: {
          id: location.id,
          name: location.name,
          barcode: location.barcode
        },
        item: {
          id: item.id,
          name: item.name,
          barcode: item.barcode
        }
      }

      message = individual_item.reusable_barcode.legacy_barcode? ?
        'Item added successfully' :
        "Item added successfully. Individual barcode: #{individual_item.individual_barcode}"

      render_success(response_data, message)
    end
  rescue ActiveRecord::RecordInvalid => e
    render_error("Validation failed: #{e.message}")
  end

  def remove_item
    location_barcode = params[:location_barcode]
    item_barcode = params[:item_barcode]
    quantity = 1

    return render_error('Location barcode is required') if location_barcode.blank?
    return render_error('Item barcode is required') if item_barcode.blank?

    location = Location.find_by(barcode: location_barcode)
    return render_error('Location not found') unless location

    item = Item.find_by(barcode: item_barcode)
    return render_error('Item not found') unless item

    inventory_item = InventoryItem.find_by(location: location, item: item)
    return render_error('Item not found in this location') unless inventory_item

    ActiveRecord::Base.transaction do
      removed_info = inventory_item.remove_individual_item!(strategy: :fifo)

      if removed_info[:completely_removed]
        response_data = {
          message: 'Item completely removed from location',
          removed_quantity: 1,
          removed_individual_item: {
            individual_barcode: removed_info[:individual_barcode],
            was_legacy_barcode: removed_info[:individual_barcode] == item.barcode,
            storage_days: removed_info[:storage_days].round(1)
          }
        }
      else
        response_data = {
          inventory_item: {
            id: inventory_item.id,
            quantity: inventory_item.quantity,
            added_at: inventory_item.added_at.iso8601
          },
          removed_quantity: 1,
          removed_individual_item: {
            individual_barcode: removed_info[:individual_barcode],
            was_legacy_barcode: removed_info[:individual_barcode] == item.barcode,
            storage_days: removed_info[:storage_days].round(1)
          }
        }
      end

      response_data.merge!({
        location: {
          id: location.id,
          name: location.name,
          barcode: location.barcode
        },
        item: {
          id: item.id,
          name: item.name,
          barcode: item.barcode
        }
      })

      render_success(response_data, 'Item removed successfully')
    end
  rescue ActiveRecord::RecordInvalid => e
    render_error("Validation failed: #{e.message}")
  end
end
```

```ruby
class ItemsController < ApplicationController
  # Enhanced print_barcodes method - unified approach
  def print_barcodes
    @items = Item.where(id: params[:item_ids])

    if @items.empty?
      redirect_to items_path, alert: 'No items selected for printing.'
      return
    end

    # Process copy quantities
    copy_quantities = params[:copies] || {}
    items_to_print = []

    @items.each do |item|
      copies = copy_quantities[item.id.to_s].to_i
      copies = 1 if copies < 1

      copies.times do
        # After migration: generate individual barcodes for printing
        items_to_print << generate_individual_barcode_for_printing(item)
      end
    end

    pdf = BarcodePrinter.generate_pdf(items_to_print, type: :item)

    send_data pdf,
              filename: "item_barcodes_#{Date.current.strftime('%Y%m%d')}.pdf",
              type: 'application/pdf',
              disposition: 'inline'
  end

private

  def generate_individual_barcode_for_printing(item)
    # Generate individual barcode for printing (not for inventory)
    sequence = ItemIdCounter.next_for_item(item)
    individual_barcode = "#{item.barcode}-#{sequence.to_s.rjust(5, '0')}"

    # Create print-ready object (not database record)
    OpenStruct.new(
      barcode: individual_barcode,
      name: item.name,
      category: item.category&.name,
      description: item.description
    )
  end
end
```

**Key Changes:**
- ✅ **Single print workflow** - No multiple printing options
- ✅ **Automatic individual barcodes** - All new printed barcodes are individual format
- ✅ **No UI changes** - Existing interface remains identical
- ✅ **No BarcodePrinter changes** - Service works with any barcode format

#### 4.3 Barcode Printing User Experience

**Before Migration:**
- User selects items and quantities on Items page
- Prints traditional item barcodes: `MILK001`, `MILK001`, `MILK001`
- Used for item-type identification and shelf labeling

**After Migration:**
- User selects items and quantities (identical interface)
- Prints individual item barcodes: `MILK001-00001`, `MILK001-00002`, `MILK001-00003`
- Each barcode represents a unique physical item instance
- Same workflow, enhanced individual tracking capability

**Beta Client Impact:**
- ✅ **No retraining needed** - Same printing process
- ✅ **No UI changes** - Familiar interface
- ✅ **Enhanced functionality** - Better inventory rotation tracking
- ✅ **Future-ready** - All new barcodes support individual item tracking

### Phase 5: Testing & Validation (Week 3)

#### 5.1 Create Comprehensive Test Suite

**File:** `test/models/individual_inventory_item_test.rb`
```ruby
require 'test_helper'

class IndividualInventoryItemTest < ActiveSupport::TestCase
  def setup
    @item = items(:whole_milk)
    @location = locations(:main_fridge)
    @inventory_item = InventoryItem.create!(
      item: @item,
      location: @location,
      added_at: Time.current
    )
  end

  test "should create individual item with barcode" do
    individual_item = @inventory_item.add_individual_item!

    assert individual_item.persisted?
    assert_not_nil individual_item.individual_barcode
    assert_equal 1, individual_item.sequence_number
  end

  test "should preserve legacy barcode for first item" do
    # Test migration scenario
    # ... test implementation
  end

  test "should implement FIFO removal correctly" do
    # Add multiple items at different times
    first_item = @inventory_item.add_individual_item!
    travel 1.hour
    second_item = @inventory_item.add_individual_item!

    # Remove should take first item (FIFO)
    removed_info = @inventory_item.remove_individual_item!(strategy: :fifo)

    assert_equal first_item.individual_barcode, removed_info[:individual_barcode]
    assert_equal 1, @inventory_item.quantity
  end

  # Additional test cases...
end
```

**File:** `test/controllers/api/v1/inventory_controller_test.rb`
```ruby
require 'test_helper'

class Api::V1::InventoryControllerTest < ActionDispatch::IntegrationTest
  def setup
    @location = locations(:main_fridge)
    @item = items(:whole_milk)
  end

  test "should add item with individual tracking" do
    post '/api/v1/add-item',
      params: {
        location_barcode: @location.barcode,
        item_barcode: @item.barcode
      },
      as: :json

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json['data']['inventory_item']['quantity']
    assert_not_nil json['data']['individual_item']['individual_barcode']
  end

  test "should maintain API compatibility" do
    # Test that responses match existing API format
    # ... test implementation
  end

  # Additional API test cases...
end
```

**File:** `test/controllers/items_controller_test.rb`
```ruby
require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @item = items(:whole_milk)
  end

  test "should print individual barcodes after migration" do
    post print_barcodes_items_path,
      params: {
        item_ids: [@item.id],
        copies: { @item.id.to_s => '3' }
      }

    assert_response :success
    assert_equal 'application/pdf', response.content_type

    # Verify that counters were incremented (3 barcodes generated)
    counter = ItemIdCounter.find_by(item: @item)
    assert_equal 3, counter.last_counter
  end

  test "should generate unique sequential barcodes" do
    # Test multiple print jobs generate sequential barcodes
    # ... test implementation
  end
end
```

#### 5.2 Performance Testing

**File:** `test/performance/individual_tracking_performance_test.rb`
```ruby
require 'test_helper'

class IndividualTrackingPerformanceTest < ActionDispatch::IntegrationTest
  test "barcode generation performance" do
    item = items(:whole_milk)

    time = Benchmark.measure do
      1000.times do
        ReusableBarcode.get_available_for_item(item)
      end
    end

    # Should complete in under 1 second
    assert time.real < 1.0
  end

  test "FIFO removal performance with large quantities" do
    # Test with 1000+ items
    # ... performance test implementation
  end
end
```

#### 5.3 API Compatibility Testing

```bash
# Run existing API tests to ensure no regressions
bin/rails test test/controllers/api/

# Run integration tests
bin/rails test test/integration/

# Run all tests
bin/rails test
```

### Phase 6: Documentation & Deployment (Week 3)

#### 6.1 Update API Documentation

**File:** `docs/api/endpoints.md` (Enhanced with individual item info)

Add sections explaining:
- New response fields (`individual_item`)
- Storage time accuracy improvements
- FIFO behavior explanation
- Barcode reuse mechanism

#### 6.2 Create Admin Dashboard Features

Optional: Create admin interface to:
- Monitor barcode pool utilization
- View individual item details
- Manually adjust FIFO/LIFO strategies
- Generate barcode pool analytics

#### 6.3 Deployment Checklist

**Pre-deployment:**
- [ ] All tests passing
- [ ] Performance benchmarks acceptable
- [ ] Database migration tested on staging
- [ ] API compatibility verified
- [ ] Documentation updated

**Deployment Steps:**
1. Deploy schema changes (Phase 1)
2. Deploy model changes (Phase 2)
3. Run data migration (Phase 3)
4. Deploy controller changes (Phase 4)
5. Validate system functionality

**Post-deployment:**
- [ ] Verify existing items still work
- [ ] Test new item additions
- [ ] Validate FIFO removal behavior
- [ ] Monitor performance metrics
- [ ] Check barcode pool utilization

## Risk Assessment & Mitigation

### High Risk
**Data Migration Failure**
- *Risk*: Migration corrupts existing inventory data
- *Mitigation*: Full database backup before migration, extensive testing on staging
- *Rollback*: Migration includes rollback functionality

**Performance Degradation**
- *Risk*: Individual tracking slows down operations
- *Mitigation*: Performance testing, optimized indexes, barcode pool pre-generation
- *Rollback*: Monitoring and alerts for response time increases

### Medium Risk
**Barcode Pool Exhaustion**
- *Risk*: Running out of available barcodes during high-volume operations
- *Mitigation*: Pool size monitoring, automatic pool expansion, alerts
- *Recovery*: Automatic pool generation background job

**API Response Size Growth**
- *Risk*: Individual item data increases response payload size
- *Mitigation*: Optional response fields, response compression, pagination for large datasets
- *Recovery*: Make individual item data optional in API responses

### Low Risk
**Legacy Barcode Conflicts**
- *Risk*: Existing item barcodes conflict with generated individual barcodes
- *Mitigation*: Namespace separation (original vs generated format), validation checks
- *Recovery*: Manual barcode reassignment process

## Success Metrics

### Technical Metrics
- [ ] 100% API compatibility maintained (all existing tests pass)
- [ ] Migration completes without data loss
- [ ] Response times remain within 95% of current performance
- [ ] Zero barcode conflicts or duplicates

### Business Metrics
- [ ] Beta client requires zero relabeling or process changes
- [ ] FIFO removal accuracy: oldest items removed first 100% of time
- [ ] Storage time accuracy: precise to the minute for all items
- [ ] System handles 10,000+ individual items without performance issues

### User Experience Metrics
- [ ] No user-facing changes or retraining required
- [ ] Enhanced storage time reporting improves inventory rotation
- [ ] System provides actionable insights about item age
- [ ] Support for both legacy and new barcode formats

### Phase 6: Enhanced Admin Features (Week 3-4)

#### 6.1 Individual Item Details View

Add detailed individual item tracking view for enhanced admin visibility.

**File:** `app/views/items/individual_items.html.erb`
```erb
<div class="breadcrumb">
  <%= link_to t('navigation.back_to_dashboard'), root_path, class: "back-link" %> |
  <%= link_to t('items.all_items'), items_path, class: "back-link" %> |
  <%= link_to @item.name, item_path(@item.barcode), class: "back-link" %>
</div>

<div class="individual-items-header">
  <h1>Individual Items: <%= @item.name %></h1>
  <p class="subtitle">Track each physical item instance with precise storage times</p>

  <div class="summary-stats">
    <div class="stat-card">
      <h3>Total Individual Items</h3>
      <span class="stat-value"><%= @individual_items.count %></span>
    </div>
    <div class="stat-card">
      <h3>Average Storage Time</h3>
      <span class="stat-value">
        <%= @individual_items.any? ? (@individual_items.sum(&:storage_days) / @individual_items.count).round(1) : 0 %> days
      </span>
    </div>
    <div class="stat-card">
      <h3>Oldest Item</h3>
      <span class="stat-value">
        <%= @individual_items.any? ? @individual_items.min_by(&:storage_days)&.storage_days&.round(1) : 0 %> days
      </span>
    </div>
  </div>
</div>

<div class="individual-items-section">
  <% if @individual_items.any? %>
    <div class="individual-items-table">
      <table>
        <thead>
          <tr>
            <th>Individual Barcode</th>
            <th>Location</th>
            <th>Added Date/Time</th>
            <th>Storage Duration</th>
            <th>Item Type</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <% @individual_items.includes(:location, :reusable_barcode).order(:added_at).each do |individual_item| %>
            <tr class="<%= 'legacy-item' if individual_item.reusable_barcode.legacy_barcode? %>">
              <td class="barcode-cell">
                <span class="barcode"><%= individual_item.individual_barcode %></span>
                <% if individual_item.reusable_barcode.legacy_barcode? %>
                  <span class="badge legacy" title="Original item from before migration">Legacy</span>
                <% end %>
              </td>
              <td class="location-cell">
                <%= link_to individual_item.location.name, location_path(individual_item.location.barcode), class: "location-link" %>
                <br><small class="barcode"><%= individual_item.location.barcode %></small>
              </td>
              <td class="datetime-cell">
                <span class="datetime"><%= individual_item.added_at.strftime("%Y-%m-%d %H:%M:%S") %></span>
                <br><small class="time-ago"><%= time_ago_in_words(individual_item.added_at) %> ago</small>
              </td>
              <td class="duration-cell">
                <% days_stored = individual_item.storage_days.round(1) %>
                <span class="storage-duration-badge <%= aging_css_class(days_stored.to_i) %>">
                  <%= days_stored %> days
                </span>
                <% if aging_enabled? %>
                  <br><small class="aging-status"><%= aging_label(days_stored.to_i) %></small>
                <% end %>
              </td>
              <td class="type-cell">
                <% if individual_item.reusable_barcode.legacy_barcode? %>
                  <span class="item-type-badge legacy">
                    🏷️ Original Item
                  </span>
                <% else %>
                  <span class="item-type-badge individual">
                    🔢 Individual Item #<%= individual_item.sequence_number %>
                  </span>
                <% end %>
              </td>
              <td class="actions-cell">
                <button type="button" class="btn btn-sm btn-secondary"
                        onclick="copyToClipboard('<%= individual_item.individual_barcode %>')"
                        title="Copy barcode to clipboard">
                  📋 Copy
                </button>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>

    <!-- FIFO/LIFO Preview -->
    <div class="removal-preview">
      <h3>Next Item to Remove (FIFO)</h3>
      <% next_item = @individual_items.min_by(&:added_at) %>
      <div class="next-removal-card">
        <span class="barcode"><%= next_item.individual_barcode %></span>
        <span class="location">in <%= next_item.location.name %></span>
        <span class="duration"><%= next_item.storage_days.round(1) %> days old</span>
      </div>
    </div>

  <% else %>
    <div class="empty-state">
      <h3>No Individual Items</h3>
      <p>This item has no individual tracking records. This may occur if:</p>
      <ul>
        <li>The item hasn't been added to inventory yet</li>
        <li>The migration hasn't been completed</li>
        <li>All items have been removed from inventory</li>
      </ul>
    </div>
  <% end %>
</div>

<style>
.individual-items-header {
  margin-bottom: 30px;
}

.summary-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin: 20px 0;
}

.stat-card {
  background: #f8f9fa;
  padding: 20px;
  border-radius: 8px;
  text-align: center;
  border-left: 4px solid #007bff;
}

.stat-card h3 {
  margin: 0 0 10px 0;
  font-size: 14px;
  color: #6c757d;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.stat-value {
  font-size: 24px;
  font-weight: bold;
  color: #495057;
}

.individual-items-table {
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.individual-items-table table {
  width: 100%;
  border-collapse: collapse;
}

.individual-items-table th,
.individual-items-table td {
  padding: 12px;
  text-align: left;
  border-bottom: 1px solid #dee2e6;
}

.individual-items-table th {
  background: #f8f9fa;
  font-weight: 600;
  color: #495057;
}

.legacy-item {
  background: #fff3cd;
}

.badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: bold;
  text-transform: uppercase;
}

.badge.legacy {
  background: #ffc107;
  color: #212529;
}

.item-type-badge {
  display: inline-block;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 500;
}

.item-type-badge.legacy {
  background: #fff3cd;
  color: #856404;
}

.item-type-badge.individual {
  background: #d1ecf1;
  color: #0c5460;
}

.removal-preview {
  margin-top: 30px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
  border-left: 4px solid #28a745;
}

.next-removal-card {
  display: flex;
  gap: 15px;
  align-items: center;
  padding: 15px;
  background: white;
  border-radius: 4px;
  margin-top: 10px;
}

.next-removal-card .barcode {
  font-family: monospace;
  font-weight: bold;
  background: #e9ecef;
  padding: 4px 8px;
  border-radius: 4px;
}
</style>

<script>
function copyToClipboard(text) {
  navigator.clipboard.writeText(text).then(function() {
    // Simple visual feedback
    event.target.textContent = '✓ Copied';
    setTimeout(() => {
      event.target.textContent = '📋 Copy';
    }, 2000);
  });
}
</script>
```

**Enhanced Items Controller:**
```ruby
class ItemsController < ApplicationController
  # ... existing methods ...

  def individual_items
    @item = Item.find_by!(barcode: params[:barcode])
    @individual_items = @item.individual_inventory_items
                             .includes(:location, :reusable_barcode)
                             .order(:added_at)
  end
end
```

**Enhanced Routes:**
```ruby
resources :items, only: [:index, :show, :new, :create, :edit, :update], param: :barcode do
  collection do
    post :print_barcodes
    get :search
  end

  member do
    get :individual_items  # New route for individual item details
  end
end
```

**Add Link to Item Show Page:**
```erb
<!-- In app/views/items/show.html.erb, add after item details -->
<div class="admin-actions">
  <%= link_to "🔍 View Individual Items", individual_items_item_path(@item.barcode),
      class: "btn btn-secondary" %>
</div>
```

#### 6.2 Benefits of Individual Item Details View

**Enhanced Admin Capabilities:**
- ✅ **Visual FIFO verification** - See exact order items will be removed
- ✅ **Legacy item identification** - Distinguish original vs. new individual items
- ✅ **Precise storage tracking** - Down to the second accuracy
- ✅ **Barcode management** - Copy individual barcodes for specific operations
- ✅ **Storage duration insights** - Average, oldest, and per-item storage times

**Operational Benefits:**
- ✅ **Audit trail** - Complete history of individual items
- ✅ **Quality control** - Identify items stored too long
- ✅ **Inventory verification** - Confirm physical vs. system inventory
- ✅ **Process optimization** - Analyze storage patterns and rotation efficiency

**Implementation Notes:**
- Optional enhancement - core system works without this view
- Provides detailed visibility for admin users
- Helps validate migration success (shows legacy vs. individual items)
- Useful for troubleshooting and inventory auditing

## Post-Implementation Enhancements

### Phase 7: Advanced Features (Future)
- Expiration date tracking per individual item
- Automated alerts for items approaching expiration
- Advanced reporting: average storage time, rotation efficiency
- API endpoints for direct individual item management
- Mobile app enhancements leveraging individual tracking
- Barcode pool analytics dashboard

### Phase 8: Analytics & Optimization (Future)
- Machine learning for optimal inventory rotation
- Predictive analytics for inventory planning
- Integration with external inventory management systems
- Advanced barcode pool optimization algorithms

## Team Requirements

**Backend Developer:** Database schema, model implementation, migration scripts
**API Developer:** Controller enhancements, API compatibility testing
**QA Engineer:** Comprehensive testing, performance validation, regression testing
**DevOps Engineer:** Deployment coordination, monitoring setup, rollback procedures

**Estimated Effort:** 15-20 developer days across 2-3 weeks

## Conclusion

This implementation plan provides a comprehensive path to individual item tracking while maintaining complete API compatibility and preserving existing client investments. The dual-layer architecture ensures existing systems continue to work while providing the foundation for advanced inventory management features.

The plan prioritizes zero-disruption migration for the beta client while establishing a scalable foundation for future enhancements.