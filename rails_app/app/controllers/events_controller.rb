# frozen_string_literal: true

# display of ResourceEvents
class EventsController < UIController
  before_action :load_resource, only: :index

  def index
    @events = ResourceEvent.resource_identifier(params[:resource_id])
                           .order(completed_at: :desc).page(params[:page])
  end

  def show
    @event = ResourceEvent.find(params[:id])
  end

  private

  def load_resource
    @resource = pg_query_service.find_by id: params[:resource_id]
  end

  def pg_query_service
    @pg_query_service ||= Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
end
