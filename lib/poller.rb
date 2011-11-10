require "teamcity-rest-client"
require "yaml"
require_relative "teamcity-rest-client-extensions"

class ProjectPoller
  @latest_build_id
  @server
  @project_defs

  class Project
    attr_reader :project_name, :artifact_name

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
    @project_defs = config["projects"].map { |pd| Project.new(pd) }
    puts @project_defs.inspect
    prepare_environment
  end

  def prepare_environment
    Dir.mkdir("downloads") unless Dir.exists?("downloads")
  end

  def check_and_deploy
    @server.projects.each do |prj|
      puts prj.name
      prj_def = @project_defs.detect {|pd| pd.project_name == prj.name}
      (prj.builds :sinceBuild => @latest_build_id).each do |b|
        artifact_url = b.artifact_path prj_def.artifact_name
        puts "Downloading #{artifact_url}"

        filename = artifact_url.split('/').last

        data = @server.artifact artifact_url
        file = File.new("downloads/#{filename}", File::CREAT | File::TRUNC | File::RDWR)
        file.write(data)
        file.close
        @latest_build_id = b.id.to_i if b.id.to_i > @latest_build_id
      end
    end
  end

  def poll
    begin
      puts "Checking for changes since build #{@latest_build_id}"
      check_and_deploy
      sleep 1
    end #while true
  end
end