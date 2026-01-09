# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported:
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'JSON'
  inflect.acronym 'CSV'
  inflect.acronym 'MARC'
  inflect.acronym 'RDA'
  inflect.acronym 'DCMI'
  inflect.acronym 'AAT'
  inflect.acronym 'IIIF'
  inflect.acronym 'OCR'
  inflect.acronym 'PDF'
  inflect.acronym 'DPI'
  inflect.acronym 'MMSID'
  inflect.acronym 'API'
  inflect.acronym 'UI'
  inflect.acronym 'XML'
end
