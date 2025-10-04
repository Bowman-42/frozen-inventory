module ApplicationHelper
  # Inventory configuration helpers
  def location_term(plural: false)
    ensure_config_loaded
    InventoryConfig.location_term(plural: plural)
  end

  def location_emoji
    ensure_config_loaded
    InventoryConfig.config.location_emoji
  end

  def aging_enabled?
    ensure_config_loaded
    InventoryConfig.aging_enabled?
  end

  def aging_threshold(type)
    InventoryConfig.aging_threshold(type)
  end

  def aging_label(days)
    InventoryConfig.aging_label(days)
  end

  def format_storage_info(days_ago)
    return "" unless aging_enabled?

    label = aging_label(days_ago)
    case days_ago
    when 0..aging_threshold(:warning)
      " (#{days_ago} days ago - #{label})"
    when (aging_threshold(:warning) + 1)..aging_threshold(:danger)
      " (#{days_ago} days ago - ⚠️ #{label})"
    else
      " (#{days_ago} days ago - 🚨 #{label})"
    end
  end

  def aging_css_class(days)
    return "" unless aging_enabled?
    return "warning" if days > aging_threshold(:warning)
    return "danger" if days > aging_threshold(:danger)
    ""
  end

  def app_title
    ensure_config_loaded
    InventoryConfig.config.app_title
  end

  private

  def ensure_config_loaded
    InventoryConfig.load_config_from_file
  end
end
