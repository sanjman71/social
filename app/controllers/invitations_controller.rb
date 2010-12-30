class InvitationsController < ApplicationController
  respond_to :html
  
  before_filter :authenticate_user!
  
  # GET /invite
  # GET /list/3/invite
  def new
    @invitation = current_user.invitations.new
  end

  # POST /invite
  def create
    @emails = (params.delete(:invitees).try(:split, ',') || []).map(&:strip)
    @emails.each do |email|
      @options    = {:recipient_email => email}
      @invitation = current_user.invitations.create!(@options)
    end
    if @emails.size == 1
      flash[:notice] = "Sent Invitation"
    else
      flash[:notice] = "Sent #{@emails.size} Invitations"
    end
    @redirect_path = invite_path
    redirect_to @redirect_path
  end

  # GET /invitees/search?q=user@widget.com
  def search
    @query  = params[:q]
    # find users matching query
    @users  = User.member.joins(:email_addresses).where(:handle.matches % "%#{@query}%" |
                          {:email_addresses => [:address.matches % "%#{@query}%"]}).map do |u|
      {'handle' => u.handle, 'email' => u.email_address, 'source' => 'Outlately'}
    end
    emails  = @users.collect{ |u| u['email'] }
    # find sent invitations matching query
    @users  += current_user.invitations.where(:recipient_email.matches % "%#{@query}%").map do |o|
      # ignore if invitee email is also a registered user
      if !emails.include?(o.recipient_email)
        {'handle' => o.recipient_email, 'email' => o.recipient_email, 'source' => 'Invite'}
      else
        nil
      end
    end.compact
    # check if query is an email address
    if @query.match(User.regex_email)
      @users += [{'handle' => @query, 'email' => @query, 'source' => 'Email'}]
    end
    # build response
    @hash   = {'status' => 'ok', 'invitees' => @users}

    respond_to do |format|
      format.json do
        render :json => @hash.to_json
      end
      format.html do
        # render :text => @hash.to_json
      end
    end
  end

end