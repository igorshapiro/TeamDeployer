require "win32ole"
#require "ruby-wmi"

class IIS
  def self.app_pool_start pool_name
    begin
      (get_app_pool pool_name).start
    rescue
    end
  end

  def self.app_pool_stop pool_name
    begin
      (get_app_pool pool_name).stop
    rescue
    end
  end

  def self.app_pool_recycle pool_name
    begin
      (get_app_pool pool_name).recycle
    rescue
    end
  end

  private
  def self.get_app_pool pool_name
    web_admin = WIN32OLE.connect("winmgmts:root\\WebAdministration")
    web_admin.get "ApplicationPool.Name='#{pool_name}'"
  end
end