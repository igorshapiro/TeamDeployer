require 'rubygems'
require "teamcity-rest-client"
require "yaml"
require_relative "teamcity-rest-client-extensions"
require_relative "iis"
require_relative "windows_service"
require 'inetmgr'
require 'zip/zip'
require 'fileutils'

class ProjectPoller
  @latest_build_id
  @server
  @project_defs

  class Project
    attr_reader :project_name, :artifact_name, :iis_app_pool, :service_name, :deploy_dir

    def initialize params
      @project_name = params["project-name"]
      @artifact_name = params["artifact-name"]
      @iis_app_pool = params["app-pool-name"]
      @service_name = params["service-name"]
      @deploy_dir = params["deploy-dir"]
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

        deploy prj_def, b.number, file.path
        #update_last_build_id b.id.to_i if b.id.to_i > @latest_build_id
      end unless prj_def.nil?
    end
  end

  def before_deploy project
    if (project.iis_app_pool)
      puts "Stopping Application pool #{project.iis_app_pool}"
      IIS.app_pool_stop project.iis_app_pool
    end
    if (project.service_name)
      WindowsService.service_stop project.service_name
    end
  end

  def after_deploy project
    if (project.iis_app_pool)
      puts "Starting Application pool #{project.iis_app_pool}"
      IIS.app_pool_start project.iis_app_pool
    end
    if (project.service_name)
      puts "Starting Windows Service: #{project.service_name}"
      WindowsService.service_start project.service_name
    end
  end

  def deploy project, version, artifact_path
    version_file_path = "#{project.deploy_dir}\\.deployed_version"
    if (File.exist? version_file_path)
      deployed_version = File.read version_file_path
      if Gem::Version.new(version) <= Gem::Version.new(deployed_version)
        return
      end
    end

    before_deploy project

    FileUtils.mkdir_p project.deploy_dir unless Dir.exist? project.deploy_dir
    FileUtils.rm_rf "#{project.deploy_dir}\\bin" if Dir.exist? "#{project.deploy_dir}\\bin"

    unzip_file artifact_path, project.deploy_dir
    file = File.new(version_file_path, "w")
    file.write(version)
    file.close

    puts "Deploying project #{project.project_name} from #{artifact_path}"
    after_deploy project
  end

  def poll
    begin
      puts "Checking for changes since build #{@latest_build_id}"
      check_and_deploy
      sleep 5
    end while true
  end

  def unzip_file (file, destination)
    Zip::ZipFile.open(file) { |zip_file|
     zip_file.each { |f|
       f_path=File.join(destination, f.name)
       FileUtils.mkdir_p(File.dirname(f_path))
       FileUtils.rm f_path if File.exist? f_path
       zip_file.extract(f, f_path) #unless File.exist?(f_path)
     }
    }
  end
end