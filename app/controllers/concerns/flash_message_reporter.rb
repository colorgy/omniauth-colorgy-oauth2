module FlashMessageReporter
  extend ActiveSupport::Concern

  included do
    before_filter :set_flash_message_from_params
  end

  private

  def set_flash_message_from_params
    return if request.env["HTTP_REFERER"].blank?
    referer_uri = URI.parse(request.env["HTTP_REFERER"])
    return unless referer_uri.host.ends_with?(core_domain)

    flash[:notice] = params[:flash][:notice] if params[:flash][:notice]
    flash[:alert] = params[:flash][:alert] if params[:flash][:alert]
  rescue
    nil
  end
end
