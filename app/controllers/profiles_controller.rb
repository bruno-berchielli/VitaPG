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

  private

  def profile_params
    params.expect(user: [ :name ])
  end
end
