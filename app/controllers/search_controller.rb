class SearchController < ApplicationController
  before_filter :authenticate_user!

  # GET /search
  # GET /search?q=sanj
  def index
    @query  = params[:q].to_s
    @users  = User.member.page(@page).per(10).scoped

    if @query.present?
      @users = @users.where(:handle.matches => "%#{@query}%").order("member_at desc")
    else
      @users = @users.order("rand()")
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

end