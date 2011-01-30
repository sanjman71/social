require 'resque'

# use default namespace for now
# Resque.redis.namespace = "resque:outlately"

if Rails.env == 'test'
  # resque tasks are performed synchronously in the test environment
  module Resque
    def self.enqueue(task, *args)
      task.perform(*args)
    end
  end

end