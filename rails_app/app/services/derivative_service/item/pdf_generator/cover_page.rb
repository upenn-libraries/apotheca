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
        THUMBNAIL_WIDTH = 100
        LOGO_WIDTH = 150
        LOGO_X_COORD = 350
        LOGO_FILE_PATH = 'app/assets/images/Penn Libraries Logo 2020_RGB.png'

        class Error < StandardError; end

        attr_reader :item

        # @param item [ItemResource, ItemResourcePresenter]
        def initialize(item)
          @item = item
        end

        # Adds a cover page to target document.
        #
        # @param [HexaPDF::Document]
        def add_to(document)
          composer = HexaPDF::Composer.new(page_size: PAGE_SIZE, margin: MARGIN)
          add_styles(composer)
          add_page_layout(composer)
          draw_main_content(composer)
          import_to_document(composer, document)
        rescue StandardError => e
          raise Error, "Failed to generate pdf cover page for item #{item.id}: #{e.message}"
        end

        private

        # Adds required styles to document composer.
        def add_styles(composer)
          composer.styles(**Styles::MAPPING)
          composer.document.config['font.map'] = Styles::FONTS
          composer.document.config['font.fallback'] = Styles::FONTS.keys
        end

        # Lays out foundational elements of the page (thumbnail, logo, and frame).
        def add_page_layout(composer)
          draw_thumbnail(composer)
          # ensure text is not placed in the space under the thumbnail by removing the rectangle from the frame
          composer.frame.remove_area(Geom2D::Rectangle(START_X_COORD, START_Y_COORD, THUMBNAIL_WIDTH + MARGIN,
                                                       composer.frame.available_height))
          draw_logo(composer)
        end

        # Adds descriptive metadata to cover page.
        def draw_main_content(composer)
          composer.text(descriptive_metadata_text(:title), style: :title)

          pdf_metadata.each do |field, value|
            next if value.blank?

            composer.text(field.to_s.titleize, style: :field)
            if value.starts_with?('http')
              composer.text(value, style: :metadata_uri, overlays: [[:link, { uri: value }]])
            else
              composer.text(value, style: :metadata_value)
            end
          end
        end

        # Imports cover page to provided document.
        def import_to_document(composer, document)
          composer.document.dispatch_message(:complete_objects)
          composer.document.validate
          document.pages.insert(0, document.import(composer.page))
        end

        def draw_thumbnail(composer)
          composer.image(thumbnail_file, width: THUMBNAIL_WIDTH, position: :float)
        end

        def draw_logo(composer)
          composer.image(logo_file, width: LOGO_WIDTH, position: [LOGO_X_COORD, START_Y_COORD])
        end

        # @return [Hash{Symbol->String (frozen)}]
        def pdf_metadata
          @pdf_metadata ||= {
            available_online: colenda_url,
            physical_location: descriptive_metadata_text(:physical_location),
            description: descriptive_metadata_text(:description),
            collection: descriptive_metadata_text(:collection),
            rights: descriptive_metadata_uri(:rights),
            rights_note: descriptive_metadata_text(:rights_note),
            date_generated: DateTime.now.to_fs(:display)
          }
        end

        # @return [String, nil]
        def descriptive_metadata_text(field)
          item.descriptive_metadata.send(field).pluck(:value).join('; ')
        end

        # @return [String, nil]
        def descriptive_metadata_uri(field)
          item.descriptive_metadata.send(field).first&.uri&.value
        end

        # @return [String (frozen)]
        def colenda_url
          PublishingService::Endpoint.colenda.public_item_url(item.unique_identifier)
        end

        # @return [File]
        def thumbnail_file
          file_id = item.thumbnail&.thumbnail&.file_id
          raise Error, "Thumbnail file is missing for item #{item.id}" unless file_id

          @thumbnail_file ||= File.new(Valkyrie::StorageAdapter.find_by(id: file_id).disk_path)
        end

        # @return [File]
        def logo_file
          @logo_file ||= File.new(Rails.root.join(LOGO_FILE_PATH))
        end

        class Styles
          LINK_COLOR = [14, 86, 150].freeze

          MAPPING = {
            base: { font_size: 14, font: 'Noto-Sans', fill_color: 'black' },
            field: { font: 'Noto-Sans bold', margin: [0, 0, 5, 15], padding: [0, 0, 0, 5] },
            metadata_value: { base: :base, margin: [0, 0, 15, 15], padding: [0, 0, 0, 10] },
            metadata_uri: { base: :metadata_value, fill_color: LINK_COLOR, font_size: 12, underline: true },
            title: { base: :base, font: 'Noto-Sans bold', font_size: 18, margin: [0, 0, 20, 15] }
          }.freeze

          FONTS_PATH = 'app/assets/fonts/noto_sans/'

          FONTS = {
            'Noto-Sans' => {
              none: Rails.root.join("#{FONTS_PATH}NotoSans-Regular.ttf"),
              bold: Rails.root.join("#{FONTS_PATH}NotoSans-Bold.ttf")
            },

            'Noto-Sans-CJK' => {
              none: Rails.root.join("#{FONTS_PATH}cjk/NotoSansCJKtc-Regular.ttf"),
              bold: Rails.root.join("#{FONTS_PATH}cjk/NotoSansCJKtc-Bold.ttf")
            },

            'Noto-Sans-Hebrew' => {
              none: Rails.root.join("#{FONTS_PATH}hebrew/NotoSansHebrew-Regular.ttf"),
              bold: Rails.root.join("#{FONTS_PATH}hebrew/NotoSansHebrew-Bold.ttf")
            },

            'Noto-Sans-Arabic' => {
              none: Rails.root.join("#{FONTS_PATH}arabic/NotoSansArabic-Regular.ttf"),
              bold: Rails.root.join("#{FONTS_PATH}arabic/NotoSansArabic-Bold.ttf")
            }
          }.freeze
        end
      end
    end
  end
end
