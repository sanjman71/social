class SuggestionsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_suggestion, :only => [:confirm, :decline, :relocate, :reschedule, :schedule, :show]
  before_filter :find_location, :only => [:relocate]
  respond_to    :html, :js

  # GET /suggestions
  def index
    @suggestions = current_user.suggestions
  end

  # GET /suggestions/1
  def show
    # @suggestion, @party initialized in before filter
    @other_party = @suggestion.other_party(@party)
  end

  # POST /suggestions/1/schedule
  def schedule
    # @suggestion, @party initialized in before filter

    # party schedules and confirms
    @suggestion.party_schedules(@party, :scheduled_at => params[:suggestion][:date])
    @suggestion.party_confirms(@party, :message => :keep, :event => 'schedule')
    flash[:notice] = I18n.t('suggestion.scheduled.flash')
  rescue AASM::InvalidTransition => e
    flash[:error] = I18n.t('suggestion.error.flash')
  rescue Exception => e
    flash[:error] = e.message
  ensure
    @redirect_to = redirect_back_path(suggestion_path(@suggestion))
    respond_to do |format|
      format.html { redirect_back_to(@redirect_to) and return }
      format.js   { render(:update) { |page| page.redirect_to(@redirect_to) } }
    end
  end

  # POST /suggestions/1/reschedule
  def reschedule
    # @suggestion, @party initialized in before filter

    # party reschedules
    @suggestion.party_reschedules(@party, :rescheduled_at => params[:suggestion][:date])
    @suggestion.party_confirms(@party, :message => :keep, :event => 'reschedule')
  rescue AASM::InvalidTransition => e
    flash[:error] = I18n.t('suggestion.error.flash')
  rescue Exception => e
    flash[:error] = e.message
  ensure
    @redirect_to = redirect_back_path(suggestion_path(@suggestion))
    respond_to do |format|
      format.html { redirect_back_to(@redirect_to) and return }
      format.js   { render(:update) { |page| page.redirect_to(@redirect_to) } }
    end
  end

  # POST /suggestions/1/relocate
  # POST /suggestions/1/relocate/5
  def relocate
    # @suggestion, @party, @location initialized in before filter
    @suggestion.party_relocates(@party, :location => @location)
    flash[:notice] = I18n.t('suggestion.relocated.flash')
  rescue AASM::InvalidTransition => e
    flash[:error] = I18n.t('suggestion.error.flash')
  rescue Exception => e
    flash[:error] = e.message
  ensure
    @redirect_to = redirect_back_path(suggestion_path(@suggestion))
    respond_to do |format|
      format.html { redirect_back_to(@redirect_to) and return }
      format.js   { render(:update) { |page| page.redirect_to(@redirect_to) } }
    end
  end

  # PUT /suggestions/1/decline
  def decline
    # @suggestion, @party initialized in before filter
    @suggestion.party_declines(@party)
    flash[:notice] = I18n.t('suggestion.declined.flash')
  rescue AASM::InvalidTransition => e
    flash[:error] = I18n.t('suggestion.error.flash')
  rescue Exception => e
    flash[:error] = e.message
  ensure
    @redirect_to = redirect_back_path(suggestion_path(@suggestion))
    respond_to do |format|
      format.html { redirect_back_to(@redirect_to) and return }
      format.js   { render(:update) { |page| page.redirect_to(@redirect_to) } }
    end
  end

  # PUT /suggestions/1/confirm
  def confirm
    # @suggestion, @party initialized in before filter
    @suggestion.party_confirms(@party)
    flash[:notice] = I18n.t('suggestion.confirmed.flash')
  rescue AASM::InvalidTransition => e
    flash[:error] = I18n.t('suggestion.error.flash')
  rescue Exception => e
    flash[:error] = e.message
  ensure
    @redirect_to = redirect_back_path(suggestion_path(@suggestion))
    respond_to do |format|
      format.html { redirect_back_to(@redirect_to) and return }
      format.js   { render(:update) { |page| page.redirect_to(@redirect_to) } }
    end
  end

  protected

  def find_suggestion
    @suggestion = current_user.suggestions.readonly(false).find(params[:id])
    @party      = @suggestion.parties.find_by_user_id(current_user.id)
  end

  def find_location
    if params[:location_id]
      @location = Location.find(params[:location_id])
    elsif params[:location]
      @location = Location.find_or_create_by_source(params[:location])
    else
      raise Exception, "missing location"
    end
  end

end