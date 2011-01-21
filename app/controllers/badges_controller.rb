class BadgesController < ApplicationController
  before_filter :authenticate_user!
  layout        'admin'
  
  privilege_required 'admin'
  
  # GET /badges
  def index
    @badges = Badge.order("id desc").all
  end
  
  # GET /badges/new
  def new
    @badge = Badge.new
  end

  # POST /badges
  def create
    @badge = Badge.create!(params[:badge])
    redirect_to(badges_path, :notice => "Created badge '#{@badge.name}'")
  rescue Exception => e
    render :action => 'new'
  end

  # GET /badges/tag_search?q=snickers
  def tag_search
    @query  = params[:q]
    @tags   = ActsAsTaggableOn::Tag.where(:name.matches => "%#{@query}%").collect(&:name)
    @hash   = Hash['status' => 'ok', 'count' => @tags.size, 'tags' => @tags]

    respond_to do |format|
      format.json do
        render :json => @hash.to_json
      end
      format.html do
        render :text => @hash.to_json
      end
    end
  end

  # PUT /badges/1/add_tags
  def add_tags
    @badge    = Badge.find(params[:id])
    @add_tags = params[:add_tags].split(',')
    @badge.add_tags(@add_tags)
    flash[:notice] = "Added tags"

    respond_to do |format|
      path = badges_path
      format.js { render(:update) { |page| page.redirect_to(path) } }
      format.html { redirect_to(path) and return }
    end
  end

end
