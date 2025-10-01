require 'prawn'
require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/prawn_outputter'
require 'stringio'

class BarcodePrinter
  LABEL_WIDTH = 105 # mm
  LABEL_HEIGHT = 42.3 # mm
  LABELS_PER_ROW = 2
  LABELS_PER_COL = 7
  LABELS_PER_PAGE = 14

  A4_WIDTH = 210 # mm
  A4_HEIGHT = 297 # mm

  def self.generate_pdf(items, type: :item)
    new.generate_pdf(items, type: type)
  end

  def generate_pdf(items, type: :item)
    Prawn::Document.new(page_size: 'A4', margin: [0, 0, 0, 0]) do |pdf|
      items.each_slice(LABELS_PER_PAGE) do |page_items|
        generate_page(pdf, page_items, type)
        pdf.start_new_page unless page_items == items.last(LABELS_PER_PAGE)
      end
    end.render
  end

  private

  def generate_page(pdf, items, type)
    # Calculate positions for 14 labels (2x7 grid) starting from absolute top
    label_width_pts = mm_to_pts(LABEL_WIDTH)
    label_height_pts = mm_to_pts(LABEL_HEIGHT)

    # Center labels horizontally on page
    margin_x = (pdf.bounds.width - (LABELS_PER_ROW * label_width_pts)) / 2

    items.each_with_index do |item, index|
      row = index / LABELS_PER_ROW
      col = index % LABELS_PER_ROW

      # Position from top-left corner (Prawn coordinates: y decreases downward)
      x = margin_x + (col * label_width_pts)
      y = pdf.bounds.height - (row * label_height_pts)  # Start from very top

      generate_label(pdf, item, x, y, label_width_pts, label_height_pts, type)
    end
  end

  def generate_label(pdf, item, x, y, width, height, type)
    pdf.bounding_box([x, y], width: width, height: height) do
      # Draw border for debugging (remove in production)
      pdf.stroke_bounds

      # Item/Location name in bold at the top
      pdf.font_size(10) do
        pdf.formatted_text_box([{text: item.name, styles: [:bold]}],
                               at: [5, height - 5],
                               width: width - 10,
                               height: 15,
                               overflow: :shrink_to_fit,
                               align: :center)
      end

      # Generate barcode using Prawn's native barcode support
      barcode = Barby::Code128B.new(item.barcode)

      # Use a more conservative barcode width approach
      # Code128 typically needs about 11 modules per character plus overhead
      barcode_height = 30
      char_count = item.barcode.length

      # Calculate approximate width: each char = ~8pts, plus margins
      estimated_width = char_count * 8 + 40
      max_width = width - 40  # Leave 20pt margin each side
      barcode_width = [estimated_width, max_width].min

      # Center the barcode horizontally
      barcode_x = (width - barcode_width) / 2

      # Calculate vertical center
      available_height = height - 35
      barcode_y = height - 20 - ((available_height - barcode_height) / 2)

      # Use Prawn's barcode annotation directly
      pdf.bounding_box([barcode_x, barcode_y], width: barcode_width, height: barcode_height) do
        barcode.annotate_pdf(pdf, {
          width: barcode_width,
          height: barcode_height,
          x: 0,
          y: 0
        })
      end

      # Barcode text below barcode
      pdf.font_size(8) do
        pdf.text_box item.barcode,
                     at: [5, barcode_y - barcode_height - 5],
                     width: width - 10,
                     height: 10,
                     align: :center
      end

      # Date for items only at the bottom
      if type == :item
        pdf.font_size(6) do
          pdf.text_box Date.current.strftime("%Y-%m-%d"),
                       at: [5, 8],
                       width: width - 10,
                       height: 8,
                       align: :center
        end
      end
    end
  end

  def mm_to_pts(mm)
    mm * 2.834645669 # 1mm = 2.834645669 points
  end
end