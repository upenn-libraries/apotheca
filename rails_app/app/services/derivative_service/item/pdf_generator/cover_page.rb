# frozen_string_literal: true

module DerivativeService
  module Item
    class PDFGenerator
      # Generate cover page for item-level PDF
      class CoverPage
        START_X_COORD = 0
        START_Y_COORD = 0
        PAGE_SIZE = :A4
        MARGIN = 36
        THUMBNAIL_WIDTH = 50
        THUMBNAIL_HEIGHT = 80
        LOGO_WIDTH = 20
        LOGO_HEIGHT = 23.333
        LOGO_X_COORD = 400
        LOGO_GAP = 5
        LOGO_COLOR = [1, 31, 91].freeze

        class Error < StandardError; end

        attr_reader :item, :composer, :page_width, :page_height

        def initialize(item:)
          @item = item
          @composer = HexaPDF::Composer.new(page_size: PAGE_SIZE, margin: MARGIN)
          @page_width = @composer.page.box.width
          @page_height = @composer.page.box.height
          set_page_layout
        end

        # generates HexaPDF::Type::Page object that can be added to a HexaPDF::Document.
        # @example
        #   document = HexaPDF::Document.new
        #   cover_page = CoverPage.new(item: item)
        #   document.pages.add(document.import(cover_page))
        # @return [HexaPDF::Type::Page]
        def generate
          draw_title
          draw_metadata
          composer.page
        rescue StandardError => e
          raise Error "Failed to generate pdf cover page: #{e.message}"
        end

        def write(path:)
          generate
          composer.document.write(path)
        end

        private

        def set_page_layout
          composer.styles(**styles)
          draw_thumbnail
          composer.frame.remove_area(Geom2D::Rectangle(0, 0, THUMBNAIL_WIDTH + MARGIN,
                                                       page_height - THUMBNAIL_HEIGHT - MARGIN))
          draw_attribution
        end

        def draw_thumbnail
          composer.image(thumbnail_file, width: THUMBNAIL_WIDTH, position: :float)
        end

        def draw_attribution
          composer.image(logo_file, width: LOGO_WIDTH, position: [LOGO_X_COORD, START_Y_COORD])
          text_start = LOGO_X_COORD + LOGO_WIDTH + LOGO_GAP
          composer.text('Penn Libraries', position: [text_start, (LOGO_HEIGHT / 2)], style: :logo_main_text)
          composer.text('University of Pennsylvania', position: [text_start, START_Y_COORD], style: :logo_sub_text)
        end

        def draw_title
          composer.text(item.descriptive_metadata.title.first.value, style: :title)
        end

        def draw_metadata
          item_metadata.each do |field, value|
            next if value.blank?

            composer.text(field.to_s.titleize, style: :field)
            composer.text(value, style: :metadata_value)
          end
        end

        def item_metadata
          METADATA_FIELDS.index_with { |field|
            item.descriptive_metadata.send(field).first&.value ||
              item.descriptive_metadata.send(field).first&.try(:uri)&.value
          }.merge({ available_online: colenda_url, date_generated: DateTime.now.to_fs(:display) })
        end

        def colenda_url
          "#{Settings.iiif.manifest.item_link_base_url}#{item.unique_identifier.gsub('ark:/', '').tr('/', '-')}"
        end

        def styles
          {
            base: { font_size: 16, font: 'Helvetica', fill_color: 'black' },
            field: { font: 'Helvetica bold', margin: [0, 0, 5, 15], padding: [0, 0, 0, 5] },
            metadata_value: { base: :base, margin: [0, 0, 10, 15], padding: [0, 0, 0, 10] },
            title: { base: :base, font: 'Helvetica bold', font_size: 22, margin: [0, 0, 15, 15] },
            logo_main_text: { base: :base, font_size: 12, fill_color: LOGO_COLOR, padding: [0, 0, 0, 8] },
            logo_sub_text: { base: :logo, overlays: [logo_overlay], font_size: 8, padding: [0, 0, 2, 0] }
          }
        end

        def logo_overlay
          lambda do |canvas, box|
            y_offset = 2
            canvas.line_width(1).stroke_color(*LOGO_COLOR).line(START_X_COORD, box.height + y_offset, box.width,
                                                                box.height + y_offset).stroke
          end
        end

        def thumbnail_file
          @thumbnail_file ||= File.new(Valkyrie::StorageAdapter.find_by(id: item.thumbnail.thumbnail.file_id).disk_path)
        end

        def logo_file
          @logo_file ||= File.new(Rails.root.join('app/assets/images/penn-shield.png'))
        end
      end
    end
  end
end
