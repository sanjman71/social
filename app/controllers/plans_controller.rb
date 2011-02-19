class PlansController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_location, :only => [:add]
  before_filter :find_going, :only => [:add]
  respond_to    :html, :json

  # GET /plans
  def index
    @user       = current_user
    @pcheckins  = @user.planned_checkins.active

    if @pcheckins.any? and @user.primary_email_address.blank?
      flash.now[:notice] = "Add an email address to your profile so we can notify you of checkins on your todo list"
    end
  end

  # PUT /plans/join/5
  def join
    @join_todo  = PlannedCheckin.find(params[:plan_id])
    @location   = @join_todo.location
    @going_at   = @join_todo.going_at

    add
  end

  # PUT /plans/add
  # PUT /plans/add/1
  def add
    # @location, @going_at initialized in before filter

    begin
      # set user to current user
      @user = current_user
      # create planned checkin
      @pcheckin = @user.planned_checkins.create!(:location => @location, :going_at => @going_at)
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

      if @join_todo
        Resque.enqueue(CheckinMailerWorker, :todo_joined, 'orig_todo' => @join_todo.id, 'new_todo' => @pcheckin.id)
      end
    rescue Exception => e
      # @location already planned
      @status   = 'error'
      @message  = e.message
    end

    # set redirect path
    @redirect_to = redirect_back_path(root_path)

    respond_with(@location) do |format|
      format.html do
        # track todo created
        flash[:tracker] = track_page("/todo/created") if @status == 'ok'
        redirect_back_to(@redirect_to) and return
      end
      format.js do
        # track todo created
        flash[:tracker] = track_page("/todo/created") if @status == 'ok'
        render(:update) { |page| page.redirect_to(@redirect_to) }
      end
      format.json do
        # track todo created
        @track_page = "/todo/created" if @status == 'ok'
        render(:json => Hash[:status => @status, :message => @message, :growls => @growls,
                             :track_page => @track_page].to_json)
      end
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

  # GET /plans/1/whatnow
  def whatnow
    @todo       = PlannedCheckin.find(params[:id])
    @user       = @todo.user
    @location   = @todo.location
  end

  protected

  def find_going
    case params[:going]
    when blank?
      @going_at = nil
    when /^[a-z]+$/
      @going_at = Chronic.parse(params[:going]).end_of_day
    when /\d+/
      @going_at = Chronic.parse(params[:going]).end_of_day
    end
  end

end
