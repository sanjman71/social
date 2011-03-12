class MessagesController < ApplicationController
  respond_to    :html, :json
  before_filter :authenticate_user!

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
    @to     = User.find_by_id(params[:message][:to])
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
    @text     = "Sent message to #{@user.handle}!"
    @growls   = [{:message => @text, :timeout => 5000}]

    # set redirect path
    @redirect_to = redirect_back_path(root_path)

  rescue Exception => e
    # set status, redirect path
    @status       = 'error'
    @redirect_to  = redirect_back_path(root_path)
  ensure
    respond_to do |format|
      format.html do
        # track page
        flash[:tracker] = track_page("/action/message/sent")
        flash[:notice]  = @text
        redirect_back_to(@redirect_to) and return
      end
      format.json { render :json => Hash[:status => @status, :message => @text, :growls => @growls,
                                         :track_page => "/action/message/sent"].to_json }
    end
  end
  
end