class PlansController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_location, :only => [:add]
  before_filter :find_expires, :only => [:add]
  respond_to    :html, :json

  # GET /plans
  def index
    @user       = current_user
    @pcheckins  = @user.planned_checkins.active
    @pexpired   = @user.planned_checkins.inactive

    if @pcheckins.any? and @user.primary_email_address.blank?
      flash.now[:notice] = "Add an email address to your profile so we can notify you of checkins on your todo list"
    end
  end

  # PUT /plans/add
  # PUT /plans/add/1
  def add
    # @location, @expires_at initialized in before filter

    begin
      # set user to current user
      @user = current_user
      # create planned checkin
      @pcheckin = @user.planned_checkins.create!(:location => @location, :expires_at => @expires_at)
      # add flash message
      flash[:notice] = "We added #{@location.name} to your todo list"
      # add growl message
      @message = I18n.t("todo.added", :days => PlannedCheckin.todo_days,
                                      :plus_points => Currency.for_completed_todo,
                                      :minus_points => Currency.for_expired_todo.abs)
      # add growl message
      @growls = [{:message => @message, :timeout => 2000}]
      # set status
      @status = 'ok'
    rescue Exception => e
      # @location already planned
      @status   = 'error'
      @message  = e.message
    end

    # set redirect path
    @redirect_to = redirect_back_path(root_path)

    respond_with(@location) do |format|
      format.html { redirect_back_to(@redirect_to) and return }
      format.js { render(:update) { |page| page.redirect_to(@redirect_to) } }
      format.json { render :json => Hash[:status => @status, :message => @message, :growls => @growls].to_json }
    end
  end

  # PUT /plans/remove/1
  def remove
    @location = Location.find(params[:location_id])
    @user     = current_user

    begin
      @locationship = @user.locationships.find_location_id(@location.id)
      @locationship.try(:decrement!, :todo_checkins)
    rescue Exception => e
      # @location not on todo list
    end

    respond_with(@location) do |format|
      format.html { redirect_back_to(root_path) and return }
    end
  end

  protected

  def find_expires
    # @expires_at = params[:expires]
    # return @expires_at unless @expires_at.present?
    case params[:expires]
    when blank?
      @expires_at = nil
    when /^[a-z]+$/
      @expires_at = Chronic.parse(params[:expires]).end_of_day
    when /\d+/
      @expires_at = Chronic(parse(params[:expire])).end_of_day
    end
  end

end
