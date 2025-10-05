class InventoryConfig
  include ActiveSupport::Configurable

  def self.config_file
    @config_file ||= Rails.root.join('config', 'inventory_settings.yml')
  end

  # Domain terminology
  config_accessor :location_singular, default: 'Fridge'
  config_accessor :location_plural, default: 'Fridges'
  config_accessor :location_emoji, default: '🏢'
  config_accessor :item_context, default: 'frozen'
  config_accessor :app_title, default: 'Frozen Inventory System'
  config_accessor :locale, default: 'en'

  # Feature toggles
  config_accessor :aging_enabled, default: true
  config_accessor :aging_warning_days, default: 120
  config_accessor :aging_danger_days, default: 180

  # Labels and descriptions
  config_accessor :aging_warning_label, default: 'getting old'
  config_accessor :aging_danger_label, default: 'very old'
  config_accessor :aging_fresh_label, default: 'fresh'

  # Industry presets
  PRESETS = {
    frozen_food: {
      location_singular: 'Fridge',
      location_plural: 'Fridges',
      location_emoji: '🏢',
      item_context: 'frozen',
      app_title: 'Frozen Inventory System',
      locale: 'en',
      aging_enabled: true,
      aging_warning_days: 120,
      aging_danger_days: 180,
      aging_warning_label: 'getting old',
      aging_danger_label: 'very old',
      aging_fresh_label: 'fresh'
    },
    warehouse: {
      location_singular: 'Warehouse',
      location_plural: 'Warehouses',
      location_emoji: '🏭',
      item_context: 'warehouse',
      app_title: 'Warehouse Management System',
      locale: 'en',
      aging_enabled: false,
      aging_warning_days: 365,
      aging_danger_days: 730,
      aging_warning_label: 'old stock',
      aging_danger_label: 'very old stock',
      aging_fresh_label: 'recent'
    },
    retail: {
      location_singular: 'Store',
      location_plural: 'Stores',
      location_emoji: '🏪',
      item_context: 'retail',
      app_title: 'Retail Inventory System',
      locale: 'en',
      aging_enabled: false,
      aging_warning_days: 180,
      aging_danger_days: 365,
      aging_warning_label: 'aging inventory',
      aging_danger_label: 'stale inventory',
      aging_fresh_label: 'new stock'
    },
    laboratory: {
      location_singular: 'Lab',
      location_plural: 'Labs',
      location_emoji: '🧪',
      item_context: 'laboratory',
      app_title: 'Laboratory Inventory System',
      locale: 'en',
      aging_enabled: true,
      aging_warning_days: 30,
      aging_danger_days: 90,
      aging_warning_label: 'expiring soon',
      aging_danger_label: 'expired',
      aging_fresh_label: 'fresh'
    }
  }.freeze

  # Apply a preset configuration
  def self.apply_preset(preset_name)
    preset = PRESETS[preset_name]
    return false unless preset

    preset.each do |key, value|
      config.send("#{key}=", value)
    end
    save_config_to_file
    true
  end

  # Save current configuration to file
  def self.save_config_to_file
    settings = {
      'app_title' => config.app_title,
      'location_singular' => config.location_singular,
      'location_plural' => config.location_plural,
      'location_emoji' => config.location_emoji,
      'item_context' => config.item_context,
      'locale' => config.locale,
      'aging_enabled' => config.aging_enabled,
      'aging_warning_days' => config.aging_warning_days,
      'aging_danger_days' => config.aging_danger_days,
      'aging_fresh_label' => config.aging_fresh_label,
      'aging_warning_label' => config.aging_warning_label,
      'aging_danger_label' => config.aging_danger_label
    }

    File.write(config_file, settings.to_yaml)
  end

  # Load configuration from file
  def self.load_config_from_file
    return if @config_loaded

    if File.exist?(config_file)
      settings = YAML.load_file(config_file)
      if settings.is_a?(Hash)
        settings.each do |key, value|
          config.send("#{key}=", value) if config.respond_to?("#{key}=")
        end
      end
    end

    @config_loaded = true
  end

  # Force reload configuration (for testing/debugging)
  def self.reload_config_from_file!
    @config_loaded = false
    load_config_from_file
  end

  # Get current preset name (if any)
  def self.current_preset
    PRESETS.each do |name, preset|
      if preset.all? { |key, value| config.send(key) == value }
        return name
      end
    end
    :custom
  end

  # Helper methods for easy access
  def self.location_term(plural: false)
    plural ? config.location_plural : config.location_singular
  end

  def self.aging_enabled?
    config.aging_enabled
  end

  def self.aging_threshold(type)
    case type
    when :warning then config.aging_warning_days
    when :danger then config.aging_danger_days
    else 0
    end
  end

  def self.aging_label(days)
    return I18n.t('aging.fresh_label') if days <= aging_threshold(:warning)
    return I18n.t('aging.warning_label') if days <= aging_threshold(:danger)
    I18n.t('aging.danger_label')
  end

  def self.app_title
    config.app_title
  end
end