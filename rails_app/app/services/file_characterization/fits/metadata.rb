# frozen_string_literal: true

module FileCharacterization
  class Fits
    # Contains metadata returned by FITS and includes helper methods to parse out commonly used fields.
    class Metadata
      CM_TO_IN = 2.54

      attr_reader :raw

      def initialize(output)
        @raw = clean_output(output)
        @xml = Nokogiri::XML.parse(raw)
      end

      def mime_type
        @mime_type ||= @xml.at_xpath('/xmlns:fits/xmlns:identification/xmlns:identity/@mimetype')&.text
      end

      def size
        @xml.at_xpath('/xmlns:fits/xmlns:fileinfo/xmlns:size')&.text.to_i
      end

      # Height of image or video file in pixels.
      #
      # @return [Integer] height in pixels
      def height
        text = if image?
                 @xml.at_xpath('/xmlns:fits/xmlns:metadata/xmlns:image/xmlns:imageHeight')&.text
               elsif video?
                 @xml.at_xpath('/xmlns:fits/xmlns:metadata/xmlns:video/xmlns:track[@type="video"]/xmlns:height')&.text
               end
        return unless text

        text = text.gsub(/\s+pixels\Z/, '')
        text.match?(/\A\d+\Z/) ? text.to_i : nil
      end

      # Width of image or video file in pixels.
      #
      # @return [Integer] width in pixels
      def width
        text = if image?
                 @xml.at_xpath('/xmlns:fits/xmlns:metadata/xmlns:image/xmlns:imageWidth')&.text
               elsif video?
                 @xml.at_xpath('/xmlns:fits/xmlns:metadata/xmlns:video/xmlns:track[@type="video"]/xmlns:width')&.text
               end
        return unless text

        text = text.gsub(/\s+pixels\Z/, '')
        text.match?(/\A\d+\Z/) ? text.to_i : nil
      end

      def md5
        @xml.at_xpath('/xmlns:fits/xmlns:fileinfo/xmlns:md5checksum')&.text
      end

      # Duration of video or audio file.
      #
      # return [Float] duration in seconds
      def duration
        # duration xpath differs based on the type of asset being attached
        text = if audio?
                 @xml.at_xpath('/xmlns:fits/xmlns:metadata/xmlns:audio/xmlns:duration')&.text
               elsif video?
                 @xml.at_xpath('/xmlns:fits/xmlns:metadata/xmlns:video/xmlns:duration')&.text
               end

        return nil unless text

        convert_duration(text)
      end

      # Dots per inch (in pixels) used when photographing the object.
      #
      # This value can be used to accurately create a print representation of the object
      # that matches the original size of the object.
      #
      # @return [Integer] dpi
      def dpi
        return unless image?

        unit = sampling_frequency_unit
        sampling = sampling_frequency

        return unless sampling && unit

        unit == 'cm' ? (sampling * CM_TO_IN).round : sampling
      end

      private

      %i[image audio video].each do |type|
        define_method("#{type}?") do
          mime_type.start_with?(type.to_s)
        end
      end

      # Return if unit is provided and it's not inches or centimeters. Unit can sometimes be
      # missing from technical metadata.
      #
      # @return [String]
      def sampling_frequency_unit
        unit = @xml.at_xpath('/xmlns:fits/xmlns:metadata/xmlns:image/xmlns:samplingFrequencyUnit')&.text
        unit&.match(/^(cm|in)/)&.captures&.first
      end

      # Extract sampling frequency from metadata
      #
      # @return [Integer, nil]
      def sampling_frequency
        x_sampling = sampling_frequency_for('x')
        y_sampling = sampling_frequency_for('y')

        x_sampling == y_sampling ? x_sampling : nil
      end

      # Return sampling frequency by axis.
      #
      # @param axis [String] x or y
      # @return [Integer, nil]
      def sampling_frequency_for(axis)
        @xml.xpath("/xmlns:fits/xmlns:metadata/xmlns:image/xmlns:#{axis}SamplingFrequency")
            .map(&:text)
            .find { |f| f.match?(/[1-9]\d*/) }
            &.to_i
      end

      # Convert duration from a formatted string to seconds
      #
      # @return [Float]
      def convert_duration(text)
        if text.match?(/\A\d+\Z/) # duration in milliseconds
          text.to_f / 1_000.0
        elsif (match = text.match(/\A((\d*\.)*\d+)\s+s\Z/)) # duration in 1.0 s
          match[1].to_f
        elsif (match = text.match(/\A(\d{1,2}):(\d{1,2}):(\d{1,2})\Z/)) # duration in 01:45:01
          (match[1].to_f * 3600) + (match[2].to_f * 60.0) + match[3].to_f
        end
      end

      def clean_output(output)
        xml = Nokogiri::XML.parse(output)
        xml.at_xpath('/xmlns:fits/xmlns:fileinfo/xmlns:filepath')&.remove
        xml.at_xpath('/xmlns:fits/xmlns:statistics')&.remove
        xml.to_xml
      end
    end
  end
end
