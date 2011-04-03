class SearchController < ApplicationController
  before_filter :authenticate_user!

  # GET /search
  # GET /search?q=sanj
  def index
    @query  = params[:q].to_s
    @users  = User.member.page(params[:page]).order("member_at desc").scoped

    if @query.present?
      @users = @users.
                joins(:city).where({:handle.matches => "%#{@query}%"} | {:'cities.name'.matches => "%#{@query}%"}).
                per(50)
    else
      @users = @users.per(10)
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

end