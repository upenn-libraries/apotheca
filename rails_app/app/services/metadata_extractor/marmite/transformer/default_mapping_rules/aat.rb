# frozen_string_literal: true

module MetadataExtractor
  class Marmite
    class Transformer
      class DefaultMappingRules
        # Module that contains AAT terms.
        module AAT
          AUTHORITY = 'aat'.freeze

          ATLASES      = { value: 'atlases',                       uri: 'http://vocab.getty.edu/aat/300028053' }.freeze
          BOOKS        = { value: 'books',                         uri: 'http://vocab.getty.edu/aat/300028051' }.freeze
          CARTOGRAPHIC = { value: 'cartographic materials',        uri: 'http://vocab.getty.edu/aat/300028052' }.freeze
          EXCERPTS     = { value: 'excerpts',                      uri: 'http://vocab.getty.edu/aat/300026939' }.freeze
          GLOBES       = { value: 'globes (cartographic spheres)', uri: 'http://vocab.getty.edu/aat/300028089' }.freeze
          JOURNALS     = { value: 'journals (periodicals)',        uri: 'http://vocab.getty.edu/aat/300215390' }.freeze
          MAGAZINES    = { value: 'magazines (periodicals)',       uri: 'http://vocab.getty.edu/aat/300215389' }.freeze
          MANUSCRIPTS  = { value: 'manuscripts (documents)',       uri: 'http://vocab.getty.edu/aat/300028569' }.freeze
          MAPS         = { value: 'maps (documents)',              uri: 'http://vocab.getty.edu/aat/300028094' }.freeze
          NEWSLETTERS  = { value: 'newsletters',                   uri: 'http://vocab.getty.edu/aat/300026652' }.freeze
          NEWSPAPERS   = { value: 'newspapers',                    uri: 'http://vocab.getty.edu/aat/300026656' }.freeze
          PERIODICALS  = { value: 'periodicals',                   uri: 'http://vocab.getty.edu/aat/300026657' }.freeze
          SCORES       = { value: 'scores (documents for music)',  uri: 'http://vocab.getty.edu/aat/300026427' }.freeze
          SERIALS      = { value: 'serials (publications)',        uri: 'http://vocab.getty.edu/aat/300026642' }.freeze
          SHEET_MUSIC  = { value: 'sheet music',                   uri: 'https://vocab.getty.edu/aat/300026430' }.freeze
        end
      end
    end
  end
end
