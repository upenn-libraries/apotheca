# frozen_string_literal: true

module DerivativeService
  module Item
    class PDFGenerator
      # Generate cover for item-level PDF. Cover can span multiple pages.
      class Cover
        PAGE_SIZE = :A4
        MARGIN = 36
        LOGO_WIDTH = 175
        LOGO_FILE_PATH = 'app/assets/images/Penn Libraries Logo 2020_RGB.png'

        class Error < StandardError; end

        attr_reader :item

        # @param item [ItemResource, ItemResourcePresenter]
        def initialize(item)
          @item = item
        end

        # Adds cover pages to target document.
        #
        # @param [HexaPDF::Document]
        def add_pages_to(target)
          document.pages.each_with_index do |page, i|
            target.pages.insert(i, target.import(page))
          end
        rescue StandardError => e
          raise Error, "Failed to generate pdf cover page for item #{item.id}: #{e.message}", cause: e
        end

        # Creates document containing cover pages.
        #
        # @return [HexaPDF::Document]
        def document
          composer = HexaPDF::Composer.new(page_size: PAGE_SIZE, margin: MARGIN)

          add_styles(composer)
          add_main_contents(composer)

          composer.document.dispatch_message(:complete_objects)
          composer.document.validate
          composer.document
        end

        private

        # Adds required styles to document composer.
        def add_styles(composer)
          composer.styles(**Styles::MAPPING)
          composer.document.config['font.map'] = Styles::FONTS
          composer.document.config['font.fallback'] = Styles::FONTS.keys
        end

        # Lays out foundational elements of the cover (logo, thumbnail, and text).
        def add_main_contents(composer)
          draw_logo(composer)
          draw_thumbnail(composer)
          draw_title(composer)
          draw_metadata(composer)
        end

        # Adds title to cover
        def draw_title(composer)
          descriptive_metadata_text(:title).each do |text|
            composer.text(text, style: :title)
          end
        end

        # Adds metadata to cover.
        def draw_metadata(composer)
          pdf_metadata.each do |field, values|
            next if values.blank?

            composer.text(field.to_s.titleize, style: :field)

            values.each do |value|
              if value.starts_with?('http')
                composer.text(value, style: :metadata_uri, overlays: [[:link, { uri: value }]])
              else
                composer.text(value, style: :metadata_value)
              end
            end
          end
        end

        def draw_thumbnail(composer)
          # Thumbnails are produced with the default VIPS DPI of 72. So, we can use the thumbnail
          # height and width in pixels to explicitly set the size of the image instead of attempting
          # to resize. Hopefully this fixes the inconsistent error we are seeing.
          thumbnail = composer.document.images.add(thumbnail_file)
          composer.image(thumbnail, width: thumbnail.width, height: thumbnail.height, position: :float, align: :right,
                                    margin: [0, 0, 15, 15])
        end

        def draw_logo(composer)
          composer.image(logo_file, width: LOGO_WIDTH, margin: [0, 0, 10, 0])
        end

        # @return [Hash{Symbol->Array<String>}]
        def pdf_metadata
          @pdf_metadata ||= {
            available_online: [digital_collections_url],
            physical_location: descriptive_metadata_text(:physical_location),
            description: descriptive_metadata_text(:description),
            collection: descriptive_metadata_text(:collection),
            rights: descriptive_metadata_uri(:rights),
            rights_note: descriptive_metadata_text(:rights_note),
            date_generated: [DateTime.now.to_fs(:display)]
          }
        end

        # @return [Array<String>]
        def descriptive_metadata_text(field)
          item.descriptive_metadata.send(field).pluck(:value)
        end

        # @return [Array<String>]
        def descriptive_metadata_uri(field)
          item.descriptive_metadata.send(field).pluck(:uri).map(&:value)
        end

        # @return [String (frozen)]
        def digital_collections_url
          PublishingService::Endpoint.digital_collections.item_url(item.id)
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
            field: { font: 'Noto-Sans bold', margin: [10, 0, 5, 0] },
            metadata_value: { base: :base, margin: [0, 0, 5, 15], padding: [0, 0, 0, 10] },
            metadata_uri: { base: :metadata_value, fill_color: LINK_COLOR, font_size: 12, underline: true },
            title: { base: :base, font: 'Noto-Sans bold', font_size: 18, margin: [0, 0, 5, 0] }
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
            },

            'Noto-Sans-Bengali' => {
              none: Rails.root.join("#{FONTS_PATH}bengali/NotoSansBengali-Regular.ttf"),
              bold: Rails.root.join("#{FONTS_PATH}bengali/NotoSansBengali-Bold.ttf")
            },

            'Noto-Sans-Thai' => {
              none: Rails.root.join("#{FONTS_PATH}thai/NotoSansThai-Regular.ttf"),
              bold: Rails.root.join("#{FONTS_PATH}thai/NotoSansThai-Bold.ttf")
            }
          }.freeze
        end
      end
    end
  end
end
