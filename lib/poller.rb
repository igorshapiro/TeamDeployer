require "teamcity-rest-client"
require "yaml"
require_relative "teamcity-rest-client-extensions"

class ProjectPoller
  @latest_build_id
  @server

  class Project
    attr_reader :project_name, :artiface_name

    def initialize params
      @project_name = params["project-name"]
      @artifact_name = params["artifact-name"]
    end
  end

  def initialize
    @latest_build_id = 1
    config = YAML.load_file("configuration.yaml")
    @server = Teamcity.new(config["server"]["host"], config["server"]["port"],
                          config["server"]["user"], config["server"]["password"])
  end

  def check_and_deploy
    @server.projects.each do |prj|
      puts prj.name

      (prj.builds :sinceBuild => @latest_build_id).each do |b|
        puts b.id
        @latest_build_id = b.id.to_i if b.id.to_i > @latest_build_id
      end
    end
  end

  def poll
    begin
      puts "Checking for changes since build #{@latest_build_id}"
      check_and_deploy
      sleep 1
    end while true
  end
end