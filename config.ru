#used by rackup

#Use bundler to select gems
require "bundler"

# load all gems in Gemfile
Bundler.require

require_relative "models/model"
require_relative "models/comment"
require_relative "models/post"
require_relative "models/sub"
require_relative "models/user"

require_relative "app"

run App
