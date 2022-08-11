# frozen_string_literal: true

# alert message application actions
class AlertMessagesController < ApplicationController
  def index
    @header_alert = AlertMessage.header
    @home_alert = AlertMessage.home
  end

  def update
    @alert_message = AlertMessage.find params[:id]
    if @alert_message.update alert_message_params
      redirect_to alert_messages_path, notice: t('.updated')
    else
      redirect_to alert_messages_path,
                  notice: t('.problem', message: @alert_message.errors.full_messages.join(', '))
    end
  end

  private

  def alert_message_params
    params.require(:alert_message).permit(:active, :message, :level)
  end
end
