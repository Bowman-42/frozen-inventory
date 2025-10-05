namespace :config do
  desc "Show current configuration"
  task :show => :environment do
    puts "Current Configuration:"
    puts "====================="
    puts "App Title: #{InventoryConfig.config.app_title}"
    puts "Location Terms: #{InventoryConfig.config.location_singular} / #{InventoryConfig.config.location_plural}"
    puts "Location Emoji: #{InventoryConfig.config.location_emoji}"
    puts "Item Context: #{InventoryConfig.config.item_context}"
    puts "Language: #{InventoryConfig.config.locale}"
    puts "Aging Enabled: #{InventoryConfig.config.aging_enabled}"
    if InventoryConfig.config.aging_enabled
      puts "Warning Threshold: #{InventoryConfig.config.aging_warning_days} days"
      puts "Danger Threshold: #{InventoryConfig.config.aging_danger_days} days"
      puts "Fresh Label: #{InventoryConfig.config.aging_fresh_label}"
      puts "Warning Label: #{InventoryConfig.config.aging_warning_label}"
      puts "Danger Label: #{InventoryConfig.config.aging_danger_label}"
    end
    puts "Current Preset: #{InventoryConfig.current_preset}"
  end

  desc "Apply a configuration preset (Usage: PRESET=warehouse rake config:apply)"
  task :apply => :environment do
    preset = ENV['PRESET']&.to_sym

    if preset.nil?
      puts "Available presets: #{InventoryConfig::PRESETS.keys.join(', ')}"
      puts "Usage: PRESET=warehouse rake config:apply"
      exit 1
    end

    if InventoryConfig.apply_preset(preset)
      puts "Successfully applied #{preset} preset!"
      Rake::Task['config:show'].invoke
    else
      puts "Invalid preset: #{preset}"
      puts "Available presets: #{InventoryConfig::PRESETS.keys.join(', ')}"
      exit 1
    end
  end
end