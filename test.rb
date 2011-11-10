require "teamcity-rest-client"
require_relative "lib/teamcity-rest-client-extensions"
require_relative "lib/poller"


#
#config["projects"].each do |prj|
#  puts prj.inspect
#end
#

poller = ProjectPoller.new
poller.poll
