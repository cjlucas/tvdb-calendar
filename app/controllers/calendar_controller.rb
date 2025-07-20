class CalendarController < ApplicationController
  def show
    @user = User.find_by!(pin: params[:pin])

    ics_content = IcsGenerator.new(@user).generate

    respond_to do |format|
      format.ics do
        send_data ics_content,
                  filename: "tvdb-calendar-#{@user.pin}.ics",
                  type: "text/calendar; charset=utf-8",
                  disposition: "attachment"
      end

      format.any do
        render plain: ics_content, content_type: "text/calendar; charset=utf-8"
      end
    end
  rescue ActiveRecord::RecordNotFound
    render plain: "User not found", status: :not_found
  end
end
