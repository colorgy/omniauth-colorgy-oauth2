module ColorgyDeviseSSOManager
  extend ActiveSupport::Concern

  @@sst_verification_method = 'RS256'

  included do
    before_filter :verify_sst
    helper_method :sign_out_url, :logout_url
  end

  # Helpers to get the core sign-out URL
  def sign_out_url
    "#{core_url}/logout"
  end

  def logout_url
    sign_out_url
  end

  # Override the destroy_user_session_path to logout from core
  def destroy_user_session_path
    sign_out_url
  end

  private

  # Getter of the core domain
  def core_domain
    @@core_domain ||= URI.parse(Devise.omniauth_configs[:colorgy].options[:client_options][:site]).host
  end

  # Getter of the core url
  def core_url
    @@core_url ||= Devise.omniauth_configs[:colorgy].options[:client_options][:site]
  end

  # Getter of the core rsa public key
  def core_rsa_public_key
    @@core_rsa_public_key ||= OpenSSL::PKey::RSA.new(ENV['CORE_RSA_PUBLIC_KEY'].gsub(/\\n/, "\n"))
  end

  # Decode the sign-on status token (sst) string and return a hash
  def decode_sst(token)
    data = JWT.decode(token, core_rsa_public_key, @@sst_verification_method)[0]

    data['issued_at'] = Time.at(data['iat'])
    data['expired_at'] = Time.at(data['exp'])
    data['updated_at'] = Time.at(data['updated_at'])

    data
  rescue JWT::DecodeError
    nil
  end

  def verify_sst
    # Skip this on test and auth callbacks
    return if Rails.env.test?
    return if controller_name == 'omniauth_callbacks'

    # Get the sst string from cookie
    sst_string = cookies[:_sst]

    # If the user's session is valid but the sst is blank,
    # sign out the user
    if user_signed_in? && sst_string.blank?
      sign_out current_user and return
    end

    # Decode the sign-on status token (sst)
    sst = decode_sst(sst_string)

    # Perform checks if the user is currently signed in
    if user_signed_in?

      # If the sst is invalid (expired or cannot be verified),
      # sign out the user
      sign_out current_user and return if sst.blank?

      # If the sst isn't belongs to the current user, sign out the user and
      # redirect to authorize path for re-authorization
      unless current_user.try(:uuid) == sst['uuid'] ||
             current_user.try(:sid) == sst['id'] ||
             current_user.try(:cid) == sst['id'] ||
             current_user.try(:id) == sst['id']
        sign_out current_user
        redirect_to user_omniauth_authorize_path(:colorgy)
        return
      end

      # If current user's update time is before the token specified time,
      # re-authentication to refresh the user's data, do this only on
      # navigational GET requests
      if sst['updated_at'].present? && request.get? && is_navigational_format?
        current_user_refreshed_at = current_user.try(:refreshed_at) ||
                                    current_user.try(:synced_at)
        if current_user_refreshed_at.is_a?(Time) && sst['updated_at'] > current_user_refreshed_at
          sign_out current_user
          redirect_to user_omniauth_authorize_path(:colorgy) and return
        end
      end

      # If the token is about to expired then redirect to core to refresh it,
      # and do this only on navigational GET requests
      if (sst['expired_at'] - Time.now < 3.days) && request.get? && is_navigational_format?
        redirect_to "#{core_url}/refresh_sst?redirect_to=#{CGI.escape(request.original_url)}" and return
      end

    # if the user isn't signed in but the sst isn't blank,
    # redirect to core authorize path
    elsif !sst.blank?
      redirect_to user_omniauth_authorize_path(:colorgy) and return
    end
  end
end
