class CheckinsController < ApplicationController
  before_filter :authenticate_user!

  def index
    # group checkins by source
    @checkins     = current_user.checkins.group_by(&:source_type)
    @checkin_logs = current_user.checkin_logs.inject(Hash[]) do |hash, log|
      mm, ss = (Time.zone.now-log.last_check_at).divmod(60)
      # track minutes ago
      hash[log.source] = mm
      hash
    end
  end

end