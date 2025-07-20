class UsersController < ApplicationController
  def create
    Rails.logger.info "UsersController#create: Starting user lookup"

    @user = User.find_or_initialize_by(pin: user_params[:pin])

    if @user.persisted?
      Rails.logger.info "UsersController#create: Found existing user #{@user.id}"
      # User already exists
      if @user.needs_sync?
        # User needs sync - start background sync and show progress
        Rails.logger.info "UsersController#create: User needs sync, starting background job"
        UserSyncIndividualJob.perform_later(@user.pin)
        render json: {
          status: "syncing",
          user_pin: @user.pin,
          calendar_url: user_calendar_url(@user.pin)
        }
      else
        # User is up to date - show calendar URL immediately
        Rails.logger.info "UsersController#create: User is up to date"
        render json: {
          status: "ready",
          user_pin: @user.pin,
          calendar_url: user_calendar_url(@user.pin)
        }
      end
    else
      # New user - create and start sync
      Rails.logger.info "UsersController#create: Creating new user"
      if @user.save
        Rails.logger.info "UsersController#create: New user created with ID #{@user.id}, starting sync"
        UserSyncIndividualJob.perform_later(@user.pin)
        render json: {
          status: "syncing",
          user_pin: @user.pin,
          calendar_url: user_calendar_url(@user.pin)
        }
      else
        Rails.logger.error "UsersController#create: Failed to save user: #{@user.errors.full_messages}"
        render json: {
          status: "error",
          errors: @user.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  rescue => e
    Rails.logger.error "UsersController#create: Exception: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: {
      status: "error",
      message: "Failed to process request. Please check your PIN."
    }, status: :unprocessable_entity
  end

  private

  def user_params
    params.require(:user).permit(:pin)
  end
end
