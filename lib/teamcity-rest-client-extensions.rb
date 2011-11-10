require 'teamcity-rest-client'

module TeamcityRestClientExtensions
  class TeamcityRestClient::HttpBasicAuthentication
    def credentials
      [@user, @password]
    end
  end

  class TeamcityRestClient::Build
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
end