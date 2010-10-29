class EmailJob < Struct.new(:params)

  def logger
    case Rails.env
    when 'development'
      @logger ||= Logger.new(STDOUT)
    else
      @logger ||= Logger.new("log/emails.log")
    end
  end

  def perform
    logger.info "#{Time.now}: [email] #{params.inspect}"

    # build object, action tuple
    tuple = [params[:object], params[:action]]
    
    begin
      case tuple
      when ['user', 'signup']
        user = User.find(params[:user_id])
        UserMailer.user_signup(user).deliver
      end
    rescue Exception => e
      logger.info "#{Time.now}: [email] exception #{e.message}"
    else
      logger.info "#{Time.now}: [email] completed"
    end
  end

end