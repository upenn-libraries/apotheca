# frozen_string_literal: true

# System-level actions
class SystemActionsController < UIController
  authorize_resource class: false

  def index; end

  def refresh_all_ils_metadata
    if EnqueueBulkRefreshIlsMetadataJob.perform_async(current_user.email)
      redirect_to system_actions_path, notice: I18n.t('actions.item.refresh_all_ILS.success')
    else
      redirect_to system_actions_path, notice: I18n.t('actions.item.refresh_all_ILS.failure')
    end
  end
end
