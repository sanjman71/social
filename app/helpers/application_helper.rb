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

  def picture_url(user, options={})
    case
    when !user.facebook_id.blank?
      "https://graph.facebook.com/#{user.facebook_id}/picture?type=square"
    when user.try(:female?)
      'http://foursquare.com/img/blank_girl.png'
    when user.try(:male?)
      'http://foursquare.com/img/blank_boy.png'
    else
      ''
    end
  end
end
