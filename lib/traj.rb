require 'rubygems'

#require 'rgeo'
#require 'builder'
#require 'date'
#require 'gsl'
#require 'k_means'

Dir.glob('./lib/traj/*.rb').each do |filename|
  require filename
end
