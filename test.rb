require "teamcity-rest-client"
require_relative "lib/teamcity-rest-client-extensions"
require_relative "lib/poller"

poller = ProjectPoller.new
poller.poll
