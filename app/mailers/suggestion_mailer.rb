class SuggestionMailer < ActionMailer::Base
  include ActionView::Helpers::DateHelper

  default :from => "outlately@jarna.com"

  def suggestion_scheduled(suggestion, scheduling_party, other_party)
    @email    = other_party.user.email_address
    @handle   = scheduling_party.user.handle

    # figure out when in days
    @distance = distance_of_time_in_words_hash(Time.zone.now, suggestion.scheduled_at)
    @days     = @distance['days'].to_i
    @when     = @days <= 1  ? 'tomorrow' : "in #{@days} days"

    unless @email.blank?
      # AppLogger.log("[email:#{@user.id}:#{@email}] todo_reminder:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => "Outlately: #{@handle} suggested meeting #{@when}")
    end
  end

  def suggestion_rescheduled(suggestion, scheduling_party, other_party)
    @email    = other_party.user.email_address
    @handle   = scheduling_party.user.handle
  
    # figure out when in days
    @distance = distance_of_time_in_words_hash(Time.zone.now, suggestion.scheduled_at)
    @days     = @distance['days'].to_i
    @when     = @days <= 1  ? 'tomorrow' : "in #{@days} days"

    unless @email.blank?
      # AppLogger.log("[email:#{@user.id}:#{@email}] todo_reminder:location:#{@location.try(:name)}")
      mail(:to => @email, :subject => "Outlately: #{@handle} re-scheduled and suggested meeting #{@when}")
    end
  end

  def suggestion_relocated(suggestion, scheduling_party, other_party)
    @email    = other_party.user.email_address
    @handle   = scheduling_party.user.handle
    @location = suggestion.location

    unless @email.blank?
      mail(:to => @email, :subject => "Outlately: #{@handle} suggested meeting at #{@location.name}")
    end
  end

end