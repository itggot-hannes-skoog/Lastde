#Load all models
#Dir["./models/*.rb"].each {|model| require model}
require_relative "../models/model"
require_relative "../models/comment"
require_relative "../models/post"
require_relative "../models/sub"
require_relative "../models/user"

#Load all helpers
#Dir["./helpers/*.rb"].each {|helper| require helper}

# Used during local development (on your own machine)
configure :development do
  puts "*******************"
  puts "* DEVELOPMENT ENV *"
  puts "*******************"

  # Enable pretty printing of Slim-generated HTML (for debugging)
  Slim::Engine.set_options pretty: true, sort_attrs: false
end

# Used when running tests (rake test:[acceptance|models|routes])
configure :test do

  # Use SQLite db in RAM (for speed & since we do not need to save data between test runs
  # TODO

end

# Load the application
require_relative "../app"
