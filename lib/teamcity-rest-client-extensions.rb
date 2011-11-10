require 'teamcity-rest-client'

module TeamcityRestClientExtensions
  class TeamcityRestClient::HttpBasicAuthentication
    def credentials
      [@user, @password]
    end
  end

  class ::Teamcity
    public
    def artifact url
      get url
    end
  end

  class TeamcityRestClient::Build
    def artifact_path artifact_name
      puts self.inspect
      build = number
      puts "Substituting #{artifact_name} with #{build}"
      url = "/repository/download/#{build_type_id}/#{id}:id/Artifacts/" + artifact_name.gsub("@build", build)
      url
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
end