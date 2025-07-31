class UsersController < ApplicationController
  def create
    TRACER.in_span('users_controller.create', attributes: {
      'user.pin' => user_params[:pin]
    }) do |span|
      @user = User.find_or_initialize_by(pin: user_params[:pin])

      if @user.persisted?
        span.set_attribute('user.status', 'existing')
        span.set_attribute('user.id', @user.id)
        
        # User already exists
        if @user.needs_sync?
          # User needs sync - start background sync and show progress
          span.set_attribute('sync.action', 'start_background_job')
          
          # Start the job and propagate trace context
          UserSyncIndividualJob.perform_later_with_trace_context(@user.pin)
          
          render json: {
            status: "syncing",
            user_pin: @user.pin,
            calendar_url: user_calendar_url(@user.pin)
          }
        else
          # User is up to date - show calendar URL immediately
          span.set_attribute('sync.action', 'up_to_date')
          render json: {
            status: "ready",
            user_pin: @user.pin,
            calendar_url: user_calendar_url(@user.pin)
          }
        end
      else
        # New user - create and start sync
        span.set_attribute('user.status', 'new')
        if @user.save
          span.set_attribute('user.id', @user.id)
          span.set_attribute('sync.action', 'start_background_job')
          
          # Start the job and propagate trace context
          UserSyncIndividualJob.perform_later_with_trace_context(@user.pin)
          
          render json: {
            status: "syncing",
            user_pin: @user.pin,
            calendar_url: user_calendar_url(@user.pin)
          }
        else
          span.set_attribute('user.save_errors', @user.errors.full_messages.join(', '))
          render json: {
            status: "error",
            errors: @user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  rescue InvalidPinError => e
    TRACER.in_span('users_controller.invalid_pin_error', attributes: {
      'user.pin' => user_params[:pin],
      'error.type' => 'InvalidPinError'
    }) do |span|
      span.record_exception(e)
      render json: {
        status: "error",
        message: "PIN Invalid"
      }, status: :unprocessable_entity
    end
  rescue => e
    TRACER.in_span('users_controller.general_error', attributes: {
      'user.pin' => user_params[:pin]
    }) do |span|
      span.record_exception(e)
      render json: {
        status: "error",
        message: "Failed to process request. Please check your PIN."
      }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:pin)
  end
end
