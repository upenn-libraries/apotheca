# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennMappingRules
      # Mapping for RDA content type to DCMI type.
      module RDAContentTypeToDCMIType
        DATASET         = { value: 'Dataset',         uri: 'http://purl.org/dc/dcmitype/Dataset'        }.freeze
        IMAGE           = { value: 'Image',           uri: 'http://purl.org/dc/dcmitype/Image'          }.freeze
        MOVING_IMAGE    = { value: 'Moving Image',    uri: 'http://purl.org/dc/dcmitype/MovingImage'    }.freeze
        PHYSICAL_OBJECT = { value: 'Physical Object', uri: 'http://purl.org/dc/dcmitype/PhysicalObject' }.freeze
        SOFTWARE        = { value: 'Software',        uri: 'http://purl.org/dc/dcmitype/Software'       }.freeze
        SOUND           = { value: 'Sound',           uri: 'http://purl.org/dc/dcmitype/Sound'          }.freeze
        STILL_IMAGE     = { value: 'Still Image',     uri: 'http://purl.org/dc/dcmitype/StillImage'     }.freeze
        TEXT            = { value: 'Text',            uri: 'http://purl.org/dc/dcmitype/Text'           }.freeze

        MAP = {
          'cartographic dataset' => DATASET,
          'computer dataset' => DATASET,
          'cartographic tactile image' => IMAGE,
          'tactile image' => IMAGE,
          'tactile notated movement' => IMAGE,
          'tactile notated music' => IMAGE,
          'cartographic moving image' => MOVING_IMAGE,
          'three-dimensional moving image' => MOVING_IMAGE,
          'two-dimensional moving image' => MOVING_IMAGE,
          'cartographic tactile three-dimensional form' => PHYSICAL_OBJECT,
          'cartographic three-dimensional form' => PHYSICAL_OBJECT,
          'tactile three-dimensional form' => PHYSICAL_OBJECT,
          'three-dimensional form' => PHYSICAL_OBJECT,
          'computer program' => SOFTWARE,
          'performed music' => SOUND,
          'sounds' => SOUND,
          'spoken word' => SOUND,
          'cartographic image' => STILL_IMAGE,
          'notated movement' => STILL_IMAGE,
          'notated music' => STILL_IMAGE,
          'still image' => STILL_IMAGE,
          'tactile text' => TEXT,
          'text' => TEXT
        }.freeze
      end
    end
  end
end
