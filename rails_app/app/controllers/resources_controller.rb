# frozen_string_literal: true

# Parent of Asset and Item Controllers
#
# Contains functionality that is shared among all resource controllers.
class ResourcesController < UIController
  private

  # @param [Symbol] type
  def serve_derivative_file(resource:, type:)
    derivative = resource.send(type)
    raise FileNotFound, "No #{type} derivative exists for asset #{resource.id}" unless resource

    file = Valkyrie::StorageAdapter.find_by id: derivative.file_id
    send_data file.read,
              type: derivative.mime_type,
              disposition: file_disposition,
              filename: derivative_filename(derivative)
  end

  # @return [Symbol]
  def file_disposition
    return :inline if params[:disposition] == 'inline'

    :attachment
  end

  # Return derivative filename. Each sub-controller must implement this method.
  #
  # @param [DerivativeResource] derivative
  # @return [String]
  def derivative_filename(derivative)
    raise NotImplementedError
  end

  # Postgres query service.
  #
  # @return [Valkyrie::MetadataAdapter]
  def pg_query_service
    @pg_query_service ||= Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
end
