class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale

  private

  def set_locale
    # Ensure configuration is loaded
    InventoryConfig.load_config_from_file

    # Set locale from configuration
    I18n.locale = InventoryConfig.config.locale || I18n.default_locale
  end
end
