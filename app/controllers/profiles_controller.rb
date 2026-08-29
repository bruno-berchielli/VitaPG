class ProfilesController < ApplicationController
  def show
  end

  def update
    if current_user.update(profile_params)
      redirect_to profile_path, notice: t(".updated")
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_appearance
    mode = params[:mode].to_s
    if %w[light dark].include?(mode)
      current_user.update(preferences: (current_user.preferences || {}).merge("mode" => mode))
    end
    redirect_back_or_to profile_path
  end

  private

  def profile_params
    params.expect(user: [ :name ])
  end
end
