class SettingsController < ApplicationController
  def show
    # Force reload configuration from file
    InventoryConfig.reload_config_from_file!

    @current_preset = InventoryConfig.current_preset
    @presets = InventoryConfig::PRESETS
    @current_config = InventoryConfig.config
  end

  def update
    if params[:preset]
      # Apply preset
      preset_name = params[:preset]&.to_sym

      if InventoryConfig.apply_preset(preset_name)
        redirect_to settings_path, notice: "Configuration updated to #{preset_name.to_s.humanize} preset."
      else
        redirect_to settings_path, alert: "Invalid preset selected."
      end
    elsif params[:custom_config]
      # Apply custom configuration
      config_params = params[:custom_config]

      begin
        # Validate required fields
        errors = []
        errors << "App Title cannot be blank" if config_params[:app_title].blank?
        errors << "Location Singular cannot be blank" if config_params[:location_singular].blank?
        errors << "Location Plural cannot be blank" if config_params[:location_plural].blank?
        errors << "Location Emoji cannot be blank" if config_params[:location_emoji].blank?
        errors << "Item Context cannot be blank" if config_params[:item_context].blank?

        if config_params[:aging_enabled] == '1'
          warning_days = config_params[:aging_warning_days].to_i
          danger_days = config_params[:aging_danger_days].to_i

          errors << "Warning threshold must be greater than 0" if warning_days <= 0
          errors << "Danger threshold must be greater than 0" if danger_days <= 0
          errors << "Danger threshold must be greater than warning threshold" if danger_days <= warning_days
          errors << "Fresh label cannot be blank" if config_params[:aging_fresh_label].blank?
          errors << "Warning label cannot be blank" if config_params[:aging_warning_label].blank?
          errors << "Danger label cannot be blank" if config_params[:aging_danger_label].blank?
        end

        if errors.any?
          redirect_to settings_path, alert: "Validation errors: #{errors.join(', ')}"
          return
        end

        # Apply configuration
        InventoryConfig.config.app_title = config_params[:app_title].strip
        InventoryConfig.config.location_singular = config_params[:location_singular].strip
        InventoryConfig.config.location_plural = config_params[:location_plural].strip
        InventoryConfig.config.location_emoji = config_params[:location_emoji].strip
        InventoryConfig.config.item_context = config_params[:item_context].strip
        InventoryConfig.config.aging_enabled = config_params[:aging_enabled] == '1'

        if InventoryConfig.config.aging_enabled
          InventoryConfig.config.aging_warning_days = config_params[:aging_warning_days].to_i
          InventoryConfig.config.aging_danger_days = config_params[:aging_danger_days].to_i
          InventoryConfig.config.aging_fresh_label = config_params[:aging_fresh_label].strip
          InventoryConfig.config.aging_warning_label = config_params[:aging_warning_label].strip
          InventoryConfig.config.aging_danger_label = config_params[:aging_danger_label].strip
        end

        InventoryConfig.save_config_to_file
        redirect_to settings_path, notice: "Custom configuration applied successfully."
      rescue => e
        redirect_to settings_path, alert: "Error applying custom configuration: #{e.message}"
      end
    else
      redirect_to settings_path, alert: "No configuration specified."
    end
  end
end