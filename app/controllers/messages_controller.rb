class MessagesController < ApplicationController
  respond_to    :html, :json
  before_filter :authenticate_user!

  # POST /messages
  def create
    @sender = current_user
    @to     = User.find_by_handle(params[:message][:to])
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
    Resque.enqueue(UserMailerWorker, :user_send_message, @options)

    # log message
    Message.log("[user:#{@sender.id}] #{@sender.handle} sent message to:#{@to.handle}, body:#{@body}")

    # set status
    @status   = 'ok'
    @text     = "Sent message!"
    @growls   = [{:message => @text, :timeout => 5000}]

    # set redirect path
    @redirect_to = redirect_back_path(root_path)
    
    respond_to do |format|
      format.html { redirect_back_to(@redirect_to) and return }
      format.json { render :json => Hash[:status => @status, :message => @text, :growls => @growls].to_json }
    end
  rescue Exception => e
    # set status, redirect path
    @status       = 'error'
    @redirect_to  = redirect_back_path(root_path)
    respond_to do |format|
      format.html { redirect_back_to(@redirect_to) and return }
      format.json { render :json => Hash[:status => @status, :message => e.message, :growls => @growls].to_json }
    end
  end
  
end