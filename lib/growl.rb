module Growl
  def self.included(base)
  end

  def growls
    @growls ||= []
  end
  
  def growl_add(options={})
    growls.push(options)
    growls
  end
end