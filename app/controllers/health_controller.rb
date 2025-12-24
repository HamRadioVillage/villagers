# frozen_string_literal: true

class HealthController < ApplicationController
  skip_before_action :load_past_unarchived_conferences

  def show
    health_status = {
      status: "ok",
      database: database_connected?,
      demo_mode: DemoMode.enabled?
    }

    if DemoMode.enabled? && DemoMode.next_reset_time
      health_status[:next_reset] = DemoMode.next_reset_time.iso8601
      health_status[:time_until_reset] = DemoMode.formatted_time_until_reset
    end

    render json: health_status
  end

  private

  def database_connected?
    ActiveRecord::Base.connection.active?
  rescue StandardError
    false
  end
end
