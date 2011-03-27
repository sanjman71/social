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
    # when 'todo'
    #   @object  = PlannedCheckin.find(params['object_id'])
    #   @options.merge!('todo_id' => @object.id)
    #   @subject = "Re: your planned checkin at #{@object.location.name}"
    end

    # compose a message
    @compose = true

    # send message
    case params[:message]
    when 'bts', 'ltp', 'sad'
      @body = I18n.t("user.message.#{params[:message]}")
    when 'compose'
      # compose a message
    end

    respond_to do |format|
      format.html do
        # track action
        track_page("/action/message/#{params[:message]}")
        # if !@compose
        #   # always show simple message page
        #   flash.now[:tracker] = ga_tracker
        #   flash.now[:notice]  = @notice
        # end
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
    @sender   = current_user
    @message  = params[:message]
    @body     = @message[:body]
    
    if @message[:to_id].present?
      # user message
      @to = User.find_by_id(@message[:to_id])
    elsif @message[:wall_id].present?
      # wall message
      @wall = Wall.find_by_id(@message[:wall_id])
    end

    # validate 'to' has an email
    if @to.present? and @to.try(:primary_email_address).blank?
      # no user or email to send to
      raise Exception, "no recipient email address"
    end

    # todo: create message object when we store in db
    # @message        = Message.new
    # @message.to     = @to.handle
    # @message.body   = @body

    # send user message
    if @to.present?
      @options = {'sender_id' => @sender.id, 'to_id' => @to.id, 'body' => @body}
      if @message[:checkin_id].present?
        @options.merge!('checkin_id' => @message[:checkin_id])
      end
      Resque.enqueue(UserMailerWorker, :user_message, @options)
      # log message
      Message.log("[user:#{@sender.id}] #{@sender.handle} sent message to:#{@to.handle}, body:#{@body}, email:#{@to.email_address}")
    elsif @wall.present?
      @wall.wall_messages.create!(:sender => @sender, :message => @body)
      # log message
      Message.log("[wall:#{@wall.id}] #{@sender.handle} wrote on chalkboard")
    end

    # set status
    @status   = 'ok'
    @text     = @to.present? ? "Sent message to #{@to.handle}!" : "Wrote on chalkboard!"
    @growls   = [{:message => @text, :timeout => 5000}]
    @goto     = params[:return_to]

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
        render :json => {:status => @status, :message => @text, :growls => @growls, :goto => @goto,
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