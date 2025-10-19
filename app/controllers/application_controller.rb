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

  # Find item by either item barcode or individual barcode
  def find_item_by_barcode(barcode)
    # First try to find by item barcode (direct lookup)
    item = Item.find_by(barcode: barcode)
    return item if item

    # If not found, try to find by individual barcode
    reusable_barcode = ReusableBarcode.find_by(barcode: barcode)
    return reusable_barcode&.item if reusable_barcode

    # If still not found, check if it's a printed individual barcode
    # Format: ORIGINALBARCODE-NNNNN (e.g., ITM9Y4W87QN-00001)
    if barcode.match?(/^.+-\d{5}$/)
      legacy_barcode = barcode.split('-')[0]
      item = Item.find_by(barcode: legacy_barcode)

      if item
        # Create the reusable barcode entry for this printed barcode
        # This happens on first scan of a printed individual barcode
        ReusableBarcode.create!(
          item: item,
          barcode: barcode,
          in_use: false,  # Will be set to true when actually used
          created_at: Time.current
        )
        return item
      end
    end

    # Not found
    nil
  end
end
