class InvitationsController < ApplicationController
  respond_to    :html
  before_filter :authenticate_user!, :except => [:claim]

  # GET /invite
  # GET /invite?to=user:5
  def new
    if params[:to].to_s.match(/user:(\d+)/)
      @to = User.find_by_id($1)
    end
    @invitation = current_user.invitations.new
    # sort friends, female first
    @friends    = (current_user.friends + current_user.inverse_friends).select{ |u| u.checkins_count > 0 }.sort_by{ |u| u.female? ? -1 : 0 }
    # partition into friends that are members and not
    @fmembers, @finvitees = @friends.partition{ |f| f.member? }
  end

  # POST /invite
  def create
    @sender   = current_user
    @subject  = params[:invitation][:subject]
    @body     = params[:invitation][:body]
    @emails   = (params.delete(:invitees).try(:split, ',') || []).map(&:strip)
    @ignored  = []
    @emails.each do |email|
      # check if email is already a member
      members     = User.with_email(email).where(:member => 1)
      if members.any?
        @ignored.push(email)
        next
      end
      @options    = {:recipient_email => email, :subject => @subject, :body => @body}
      @invitation = current_user.invitations.create!(@options)
    end
    case @emails.size - @ignored.size
    when 0
      flash[:notice]  = "No Invitations Sent."
    when 1
      flash[:notice]  = "Sent Invitation."
      flash[:tracker] = track_event('Invite', 'Message')
      Invitation.log("[user:#{@sender.id}] #{@sender.handle} invited #{@emails.join(',')}")
    else
      flash[:notice]  = "Sent #{@emails.size} Invitations."
      flash[:tracker] = track_event('Invite', 'Message')
      Invitation.log("[user:#{@sender.id}] #{@sender.handle} invited #{@emails.join(',')}")
    end
    if @ignored.any?
      if @ignored.size == 1
        flash[:notice] += " There is already a member with email #{@ignored.join(', ')}"
      else
        flash[:notice] += " There are already members with emails #{@ignored.join(', ')}"
      end
    end

    respond_to do |format|
      format.html { redirect_to(invite_path) }
    end
  end

  # GET /invite/claim/123435
  def claim
    # check 'invitation_token'
    if Invitation.find_by_token(params[:invitation_token])
      # set session 'invitation_token'
      session[:invitation_token] = params[:invitation_token]
    end

    redirect_to new_user_session_path and return
  end

  # GET /invitees/search?q=user@widget.com
  def search
    @query  = params[:q]
    # find users matching query
    @users  = User.joins(:email_addresses).where(:handle.matches % "%#{@query}%" |
                         {:email_addresses => [:address.matches % "%#{@query}%"]}).map do |u|
      {'handle' => u.handle, 'email' => u.email_address, 'source' => u.member ? 'Member' : 'User'}
    end
    emails  = @users.collect{ |u| u['email'] }
    # find sent invitations matching query
    @users  += current_user.invitations.where(:recipient_email.matches % "%#{@query}%").map do |o|
      # ignore if invitee email is also a registered user
      if !emails.include?(o.recipient_email)
        {'handle' => o.recipient_email, 'email' => o.recipient_email, 'source' => 'Invited'}
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

  # GET /invite/poke?invitee_id=5
  def poke
    @poker    = current_user
    @invitee  = User.find(params[:invitee_id])

    # check if invitee is a friend of the current user
    @friend_ids = @poker.friendships.select(:friend_id).collect(&:friend_id) +
                  @poker.inverse_friendships.select(:user_id).collect(&:user_id)

    if @friend_ids.include?(@invitee.id)
      # invitee is a friend, send user to invite page
      @goto     = invite_path(:to => "user:#{@invitee_id}")
      @hash     = {'status' => 'ok', 'goto' => @goto}
    else
      # invitee is not a friend, find member friend and create invite poke
      @poke     = InvitePoke.find_or_create(@invitee, @poker)
      @growls   = [{:message => "Thanks, we'll ask them to join the site.", :timeout => 5000}]
      @hash     = {'status' => 'ok', 'poke_id' => @poke.id, 'growls' => @growls}
    end
  rescue Exception => e
    @hash = {'status' => 'error', 'message' => e.message}
  ensure
    respond_to do |format|
      format.json do
        render :json => @hash.to_json
      end
    end
  end

end