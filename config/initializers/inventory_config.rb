# Initialize inventory configuration
Rails.application.config.to_prepare do
  # Load configuration from file if it exists, or apply default preset
  if File.exist?(InventoryConfig.config_file)
    InventoryConfig.load_config_from_file
  else
    InventoryConfig.apply_preset(:frozen_food)
  end
end