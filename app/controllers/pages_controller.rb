class PagesController < HighVoltage::PagesController
  layout 'redesign'

  def show
    render :template => current_page
  end

end