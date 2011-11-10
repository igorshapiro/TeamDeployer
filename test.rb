require "teamcity-rest-client"
require "yaml"

class TeamcityRestClient::HttpBasicAuthentication
  def credentials
    [@user, @password]
  end
end

class TeamcityRestClient::Build
  def artifacts

  end

  def dump
    puts self.inspect

    #puts teamcity.authentication.get
    #puts open(href, :http_basic_authentication => teamcity.authentication.credentials).read();
  end
end
class TeamcityRestClient::Project
  def dump
    puts name

    builds.each do |bt|
      bt.dump
    end
  end
end

config = YAML.load_file("configuration.yaml")
server = Teamcity.new(config["server"]["host"], config["server"]["port"],
                      config["server"]["user"], config["server"]["password"])

config["projects"].each do |prj|
  puts prj.inspect
end

server.projects.each do |prj|
  #puts prj.inspect
  prj.dump
end
