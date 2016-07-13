# API to create IIIF Authentication access tokens
class IiifTokenController < ApplicationController
  def create
    token = mint_bearer_token unless current_user.anonymous_locatable_user?

    write_bearer_token_cookie(token) if token

    respond_to do |format|
      format.html { redirect_to callback: callback_value, format: 'js' }
      format.js do
        response = if token
                     {
                       accessToken: token,
                       tokenType: 'Bearer',
                       expiresIn: 3600
                     }
                   else
                     { error: 'missingCredentials', description: '' }
                   end

        status = if callback_value || token
                   :ok
                 else
                   :unauthorized
                 end

        render json: response.to_json, callback: callback_value, status: status
      end
    end
  end

  private

  def allowed_params
    params.permit(:callback)
  end

  def callback_value
    allowed_params[:callback]
  end

  def mint_bearer_token
    encode_credentials(current_user.token).sub('Bearer ', '')
  end

  def write_bearer_token_cookie(token)
    # webauth users already have a webauth cookie; no additional cookie needed
    return if current_user.webauth_user?

    cookies[:bearer_token] = {
      value: token,
      expires: 1.hour.from_now,
      httponly: true,
      secure: request.ssl?
    }
  end
end
