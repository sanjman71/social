class MessagesController < ApplicationController
  respond_to    :html, :json, :mobile
  before_filter :authenticate_user_with_token, :only => [:user_compose, :wall_compose]
  before_filter :authenticate_user!
  before_filter :find_user, :only => [:user_compose, :wall_compose]
  before_filter :detect_mobile_request

  # GET /users/1/re/checkin/5/message/bts - 'be there soon'
  # PUT /users/1/re/checkin/5/message/sad - 'share a drink?'
  # GET /users/1/re/checkin/5/message/ltp - 'love that place'
  # GET /users/1/re/checkin/5/message/compose
  # GET /users/1/message/compose
  def user_compose
    # @user initialized in before filter

    # set sender and options
    @sender   = current_user
    @options  = {'sender_id' => @sender.id, 'to_id' => @user.id}

    case params[:object_type]
    when 'checkin'
      @object  = Checkin.find(params['object_id'])
      @options.merge!('checkin_id' => @object.id)
      @subject = "Re: your checkin at #{@object.location.name}"
    when 'todo'
      @object  = PlannedCheckin.find(params['object_id'])
      @options.merge!('todo_id' => @object.id)
      @subject = "Re: your planned checkin at #{@object.location.name}"
    end

    # send message
    case params[:message]
    when 'bts'
      Resque.enqueue(UserMailerWorker, :user_be_there_soon_message, @options)
      @notice = "We'll send #{@user.handle} a message saying you'll be there soon"
    when 'ltp'
      Resque.enqueue(UserMailerWorker, :user_love_that_place_message, @options)
      @notice = "We'll let #{@user.handle} know that"
    when 'sad'
      Resque.enqueue(UserMailerWorker, :user_share_drink_message, @options)
      @notice = "We'll send #{@user.handle} a message saying you'd like to grab a drink"
    when 'compose'
      # compose a message
      @compose = true
    end

    respond_to do |format|
      format.html do
        # track action
        track_page("/action/message/#{params[:message]}")
        # if false #user_signed_in?
        #   # skip this for now
        #   flash[:tracker] = ga_tracker
        #   flash[:notice]  = @notice
        #   redirect_to(redirect_back_path(user_path(@user))) and return
        if !@compose
          # always show simple message page
          flash.now[:tracker] = ga_tracker
          flash.now[:notice]  = @notice
        end
      end
      format.json do
        # track action and send growl message
        @track_page = "/action/message/#{params[:message]}"
        @growls     = [{:message => @notice, :timeout => 2000}]
        @json       = {'status' => 'ok', 'growls' => @growls, 'track_page' => @track_page}.to_json
        render(:json => @json) and return
      end
      format.mobile do
      end
    end
  rescue Exception => e
    Rails.logger.debug("user#message exception: #{e.message}")
  end

  # GET /checkins/1/wall/compose
  def wall_compose
    @sender = current_user

    case params[:object_type]
    when 'checkin'
      @object = Checkin.find(params['object_id'])
    when 'todo'
      @object = PlannedCheckin.find(params['object_id'])
    end
  end

  # POST /messages
  def create
    @sender = current_user
    @to     = User.find_by_id(params[:message][:to_id])
    @body   = params[:message][:body]

    # validate 'to' has an email
    if @to.try(:primary_email_address).blank?
      # no user or email to send to
      raise Exception, "no recipient email address"
    end

    # todo: create message object when we store in db
    # @message        = Message.new
    # @message.to     = @to.handle
    # @message.body   = @body

    # send message
    @options = {'sender_id' => @sender.id, 'to_id' => @to.id, 'body' => @body}
    Resque.enqueue(UserMailerWorker, :user_message, @options)

    # log message
    Message.log("[user:#{@sender.id}] #{@sender.handle} sent message to:#{@to.handle}, body:#{@body}")

    # set status
    @status   = 'ok'
    @text     = "Sent message to #{@to.handle}!"
    @growls   = [{:message => @text, :timeout => 5000}]

    # set redirect path
    @redirect_to = redirect_back_path(root_path)

  rescue Exception => e
    # set status, redirect path
    @status       = 'error'
    @text         = e.message
    @redirect_to  = redirect_back_path(root_path)
  ensure
    respond_to do |format|
      format.html do
        # track page
        flash[:tracker] = track_page("/action/message/sent")
        flash[:notice]  = @text
        redirect_back_to(@redirect_to) and return
      end
      format.json do
        render :json => {:status => @status, :message => @text, :growls => @growls,
                         :track_page => "/action/message/sent"}.to_json
      end
      format.mobile do
        # track page
        flash[:tracker] = track_page("/action/message/sent")
        flash[:notice]  = @text
        render :text => @text
      end
    end
  end

  protected

  def find_user
    @user = User.find(params[:id])
  end

end