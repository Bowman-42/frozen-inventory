class SettingsController < ApplicationController
  def show
    # Force reload configuration from file
    InventoryConfig.reload_config_from_file!

    @current_preset = InventoryConfig.current_preset
    @presets = localized_presets
    @current_config = InventoryConfig.config
    @available_locales = {
      'en' => 'English',
      'es' => 'Español',
      'fr' => 'Français',
      'de' => 'Deutsch',
      'sv' => 'Svenska',
      'da' => 'Dansk',
      'no' => 'Norsk',
      'nl' => 'Nederlands',
      'pl' => 'Polski'
    }
    @localized_defaults = view_context.localized_defaults
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
        errors << "Invalid locale" unless ['en', 'es', 'fr', 'de', 'sv', 'da', 'no', 'nl', 'pl'].include?(config_params[:locale])

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
        InventoryConfig.config.locale = config_params[:locale]
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

  private

  def localized_presets
    {
      frozen_food: {
        location_singular: t('defaults.location_singular'),
        location_plural: t('defaults.location_plural'),
        location_emoji: '🏢',
        item_context: 'frozen',
        app_title: t('defaults.app_title'),
        locale: I18n.locale.to_s,
        aging_enabled: true,
        aging_warning_days: 120,
        aging_danger_days: 180,
        aging_warning_label: t('aging.warning_label'),
        aging_danger_label: t('aging.danger_label'),
        aging_fresh_label: t('aging.fresh_label')
      },
      warehouse: {
        location_singular: t('settings.presets.warehouse_location_singular', default: 'Warehouse'),
        location_plural: t('settings.presets.warehouse_location_plural', default: 'Warehouses'),
        location_emoji: '🏭',
        item_context: 'warehouse',
        app_title: t('settings.presets.warehouse_app_title', default: 'Warehouse Management System'),
        locale: I18n.locale.to_s,
        aging_enabled: false,
        aging_warning_days: 365,
        aging_danger_days: 730,
        aging_warning_label: t('settings.presets.warehouse_warning_label', default: 'old stock'),
        aging_danger_label: t('settings.presets.warehouse_danger_label', default: 'very old stock'),
        aging_fresh_label: t('settings.presets.warehouse_fresh_label', default: 'recent')
      },
      retail: {
        location_singular: t('settings.presets.retail_location_singular', default: 'Store'),
        location_plural: t('settings.presets.retail_location_plural', default: 'Stores'),
        location_emoji: '🏪',
        item_context: 'retail',
        app_title: t('settings.presets.retail_app_title', default: 'Retail Inventory System'),
        locale: I18n.locale.to_s,
        aging_enabled: false,
        aging_warning_days: 180,
        aging_danger_days: 365,
        aging_warning_label: t('settings.presets.retail_warning_label', default: 'aging inventory'),
        aging_danger_label: t('settings.presets.retail_danger_label', default: 'stale inventory'),
        aging_fresh_label: t('settings.presets.retail_fresh_label', default: 'new stock')
      },
      laboratory: {
        location_singular: t('settings.presets.laboratory_location_singular', default: 'Lab'),
        location_plural: t('settings.presets.laboratory_location_plural', default: 'Labs'),
        location_emoji: '🧪',
        item_context: 'laboratory',
        app_title: t('settings.presets.laboratory_app_title', default: 'Laboratory Inventory System'),
        locale: I18n.locale.to_s,
        aging_enabled: true,
        aging_warning_days: 30,
        aging_danger_days: 90,
        aging_warning_label: t('settings.presets.laboratory_warning_label', default: 'expiring soon'),
        aging_danger_label: t('settings.presets.laboratory_danger_label', default: 'expired'),
        aging_fresh_label: t('settings.presets.laboratory_fresh_label', default: 'fresh')
      }
    }
  end
end