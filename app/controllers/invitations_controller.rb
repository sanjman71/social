class InvitationsController < ApplicationController
  respond_to    :html
  before_filter :authenticate_user!

  # GET /invite
  # GET /invite?to=user:5
  def new
    if params[:to].to_s.match(/user:(\d+)/)
      @to = User.find_by_id($1)
    end
    @invitation = current_user.invitations.new
    # find friends with checkins
    @friends    = (current_user.friends + current_user.inverse_friends).select{ |u| u.checkins_count > 0 }.sort_by{ |u| -1 * u.checkins_count }
    # partition into friends that are members and not
    @fmembers, @finvitees = @friends.partition{ |f| f.member? }
  end

  # POST /invite
  def create
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
      flash[:notice] = "No Invitations Sent"
    when 1
      flash[:notice] = "Sent Invitation"
    else
      flash[:notice] = "Sent #{@emails.size} Invitations"
    end
    if @ignored.any?
      if @ignored.size == 1
        flash[:notice] += "<br />There is already a member with email #{@ignored.join(', ')}"
      else
        flash[:notice] += "<br />There are already members with emails #{@ignored.join(', ')}"
      end
    end
    @redirect_path = invite_path
    redirect_to @redirect_path
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

end