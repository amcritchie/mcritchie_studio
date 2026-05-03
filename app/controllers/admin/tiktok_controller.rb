module Admin
  # One-time OAuth handshake to obtain TIKTOK_REFRESH_TOKEN + TIKTOK_OPEN_ID
  # for the @turfmonstershow account. After getting these values, copy them
  # into ~/projects/.env and the 🐊 TikTok 1Password item.
  class TiktokController < ApplicationController
    before_action :require_admin

    def connect
      state = SecureRandom.hex(16)
      session[:tiktok_oauth_state] = state
      redirect_to(
        Tiktok::OAuthClient.authorize_url(
          redirect_uri: callback_url,
          state:        state
        ),
        allow_other_host: true
      )
    end

    def callback
      expected_state = session.delete(:tiktok_oauth_state)
      if params[:state].blank? || params[:state] != expected_state
        return render plain: "OAuth state mismatch — restart the connect flow.", status: :bad_request
      end
      if params[:error].present?
        return render plain: "TikTok denied authorization: #{params[:error]} #{params[:error_description]}", status: :bad_request
      end

      json = Tiktok::OAuthClient.exchange_code(code: params[:code], redirect_uri: callback_url)
      @access_token  = json["access_token"]
      @refresh_token = json["refresh_token"]
      @open_id       = json["open_id"]
      @scope         = json["scope"]
      @expires_in    = json["expires_in"]
    rescue StandardError => e
      render plain: "TikTok token exchange failed: #{e.message}", status: :bad_request
    end

    private

    def callback_url
      url_for(controller: "admin/tiktok", action: "callback", only_path: false)
    end
  end
end
