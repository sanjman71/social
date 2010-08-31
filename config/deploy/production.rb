# Create hosts hash, especially useful when there is more than 1 host
hosts             = Hash.new
hosts[:app1]      = '67.23.46.244:30001'   # internal ip:
hosts[:db1]       = '67.23.46.244:30001'

# Set roles
role :app,          hosts[:app1]
role :web,          hosts[:app1]
role :sphinx,       hosts[:app1]
role :dj,           hosts[:app1]
role :db,           hosts[:db1], :primary => true

# Set rails environment
set :rails_env,     'production'