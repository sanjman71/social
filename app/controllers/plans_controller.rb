class PlansController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_location, :only => [:add]
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
    # @location initialized in before filter

    begin
      # set user to current user
      @user = current_user
      # create planned checkin
      @pcheckin = @user.planned_checkins.create(:location => @location)
      if @pcheckin.valid?
        # add flash message
        flash[:notice] = "We added #{@location.name} to your todo list"
        # add growl message
        @message = I18n.t("todo.added", :days => PlannedCheckin.todo_days,
                                        :plus_points => Currency.for_completed_todo,
                                        :minus_points => Currency.for_expired_todo.abs)
        # add growl message
        @growls = [{:message => @message, :timeout => 2000}]
      end
      # set status
      @status   = 'ok'
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
