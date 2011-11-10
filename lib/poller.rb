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
    begin
      file = File.new("last_build_id")
      @latest_build_id = file.read.to_i
      file.close
    rescue
    end

    config = YAML.load_file("configuration.yaml")
    @server = Teamcity.new(config["server"]["host"], config["server"]["port"],
                          config["server"]["user"], config["server"]["password"])
    @project_defs = config["projects"].map { |pd| Project.new(pd) }
    prepare_environment
  end

  def update_last_build_id build_id
    @latest_build_id = build_id

    file = File.new("last_build_id", "w")
    file.write(@latest_build_id.to_s)
    file.close
  end

  def prepare_environment
    Dir.mkdir("downloads") unless Dir.exists?("downloads")
  end

  def check_and_deploy
    @server.projects.each do |prj|
      prj_def = @project_defs.detect {|pd| pd.project_name == prj.name}
      (prj.builds :sinceBuild => @latest_build_id, :status => "SUCCESS").each do |b|
        puts b.commit_message
        artifact_url = b.artifact_path prj_def.artifact_name
        puts "Downloading #{artifact_url}"

        filename = artifact_url.split('/').last

        begin
          data = @server.resource artifact_url
        rescue
          puts "Unable to download #{artifact_url}"
          next
        end

        file = File.new("downloads/#{filename}", "wb")
        file.write(data)
        file.close

        deploy prj_def, file.path
        update_last_build_id b.id.to_i if b.id.to_i > @latest_build_id
      end unless prj_def.nil?
    end
  end

  def deploy project, artifact_path
    puts "Deploying project #{project.project_name} from #{artifact_path}"
  end

  def poll
    begin
      puts "Checking for changes since build #{@latest_build_id}"
      check_and_deploy
      sleep 1
    end #while true
  end
end