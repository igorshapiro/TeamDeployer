require 'teamcity-rest-client'
require 'rexml/document'

module TeamcityRestClientExtensions
  class TeamcityRestClient::HttpBasicAuthentication
    def credentials
      [@user, @password]
    end
  end

  class ::Teamcity
    public
    def resource url
      prefix = url ""
      relative_url = (url.start_with? prefix) ? url.sub(prefix, "") : url
      #puts "Loading resource #{relative_url}"
      get relative_url
    end
  end

  class TeamcityRestClient::Build
    def artifact_path artifact_name
      "/repository/download/#{build_type_id}/#{id}:id/Artifacts/" + artifact_name.gsub("@build", number)
    end

    def commit_message
      xml = REXML::Document.new (teamcity.resource href)
      changes_href = xml.root.elements["changes"].attributes["href"]
      xml = REXML::Document.new (teamcity.resource changes_href)
      changes = xml.root.elements["change"]
      return "" if changes.nil?
      changes = [changes] unless changes.is_a? Array
      commit_message_hrefs = changes.collect{|ce| ce.attributes["href"]}.map { |href|
        (REXML::Document.new (teamcity.resource href)).root.elements["comment"].text
      }
      commit_message_hrefs.join("\r\n")
    end
  end
end