module Github
  class ConfigPath
    APP_NAME = 'github-repos'

    # @param [String] target
    # @param [String] legacy_path
    def initialize(target, legacy_path = nil)
      @target = target
      @legacy_file = legacy_path
    end

    def get
      unless @legacy_file.nil?
        # Fallback to legacy behavior if legacy path exists
        legacy_file = File.expand_path(@legacy_file)
        return legacy_file if File.file?(legacy_file)
      end

      xdg_config_home = ENV['XDG_CONFIG_HOME'] || File.join(ENV['HOME'], '.config')
      File.join(xdg_config_home, APP_NAME, @target)
    end
  end
end
