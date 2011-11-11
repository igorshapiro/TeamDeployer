class WindowsService
  def self.service_start service_name
    %x[SC start #{service_name}]
  end

  def self.service_stop service_name
    %x[SC stop #{service_name}]
  end
end