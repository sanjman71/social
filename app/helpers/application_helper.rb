module ApplicationHelper

  def title(page_title)
    content_for(:title)  { page_title }
  end
  
  def javascript(*files)
    content_for(:javascript) { javascript_include_tag(*files) }
  end

  def stylesheet(*files)
    content_for(:stylesheet) { stylesheet_link_tag(*files) }
  end
  
  def robots(*args)
    @robots = args.join(",")
  end

  FLASH_TYPES = [:error, :warning, :success, :message, :notice]

  def display_flash(force = false)
    if force || @flash_displayed.nil? || @flash_displayed == false
      @flash_displayed = true
      render :partial => "shared/flash.html.haml", :object => (flash.nil? ? {} : flash)
    end
  end

  def display_alerts
    @alerts = current_user.try(:alerts)
    if !@alerts.blank? and (@alerts_displayed.nil? || @alerts_displayed == false)
      @alerts_displayed = true
      # remove each alert before displaying
      @alerts.each { |a| a.destroy rescue nil }
      render :partial => "shared/alerts.html.haml", :locals => {:alerts => @alerts}
    end
  end

  # build user display name based on context of the current user
  def user_display_name(user, current_user, me = 'Me')
    case
    when user.blank?
      ''
    when user == current_user
      me
    else
      user.handle
    end
  end

  def build_missing_oauth_links
    missing_oauths = []
    return missing_oauths if !user_signed_in?
    if current_user.facebook_id.blank?
      # missing_oauths << link_to("Link your Facebook account", user_oauth_authorize_url(:facebook))
      missing_oauths << link_to(image_tag('facebook_32.png'), user_oauth_authorize_url(:facebook),
                                :alt => 'Link facebook', :title => 'Link facebook', :class => 'logo')
    end
    if current_user.foursquare_id.blank?
      # missing_oauths << link_to("Link your Foursquare account", oauth_initiate_path(:foursquare))
      missing_oauths << link_to(image_tag('foursquare_32.png', :size => '29x29'), oauth_initiate_path(:foursquare),
                                :alt => 'Link foursquare', :title => 'Link foursquare', :class => 'logo')
    end
    # deprecated: until we figure out why twitter is useful
    # if current_user.twitter_id.blank?
    #   # missing_oauths << link_to("Link your Twitter account", oauth_initiate_path(:twitter))
    #   missing_oauths << link_to(image_tag('twitter_32.png', :size => '32x32'), oauth_initiate_path(:twitter),
    #                             :alt => 'Link twitter', :title => 'Link twitter', :class => 'logo')
    # end
    missing_oauths
  end

  def user_profile_blurb(user)
    "#{user.gender_name.try(:titleize)} / #{user.city.try(:name) || 'Unknown'}"
  end
  
end
