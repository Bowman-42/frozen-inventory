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

  def javascript_translations
    {
      items_selected: {
        zero: t('items.items_selected.zero'),
        one: t('items.items_selected.one'),
        other: t('items.items_selected.other')
      },
      print_labels: {
        zero: t('items.print_labels.zero'),
        one: t('items.print_labels.one'),
        other: t('items.print_labels.other')
      },
      ready_to_print: {
        one: t('items.ready_to_print.one'),
        other: t('items.ready_to_print.other')
      },
      positions_selected: {
        zero: t('items.positions_selected.zero'),
        one: t('items.positions_selected.one'),
        other: t('items.positions_selected.other')
      }
    }.to_json.html_safe
  end

  def localized_defaults
    {
      app_title: t('defaults.app_title'),
      location_singular: t('defaults.location_singular'),
      location_plural: t('defaults.location_plural'),
      aging_fresh_label: t('aging.fresh_label'),
      aging_warning_label: t('aging.warning_label'),
      aging_danger_label: t('aging.danger_label')
    }
  end

  private

  def ensure_config_loaded
    InventoryConfig.load_config_from_file
  end
end
