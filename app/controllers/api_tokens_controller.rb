class ApiTokensController < ApplicationController
  def index
    @api_tokens = current_user.api_tokens.order(created_at: :desc)
  end

  def create
    token = current_user.api_tokens.new(api_token_params)
    if token.save
      # The plaintext is only available on this in-memory instance; carry it
      # through the redirect so the index can show it exactly once.
      flash[:new_api_token] = token.plaintext_token
      redirect_to api_tokens_path, notice: "API token created. Copy it now — it won't be shown again."
    else
      redirect_to api_tokens_path, alert: token.errors.full_messages.to_sentence
    end
  end

  def destroy
    token = current_user.api_tokens.find(params[:id])
    token.revoke!
    redirect_to api_tokens_path, notice: "API token revoked."
  end

  private

  def api_token_params
    params.require(:api_token).permit(:name)
  end
end
