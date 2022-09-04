module Railspress
  require 'railspress/global_vars'

  class Engine < ::Rails::Engine
    # isolate_namespace Railspress

    ActiveSupport.on_load :action_controller do
      if defined? helper
        helper Railspress::Engine.helpers
      else
        ::ActionController::Base.send(:include, Railspress::Engine.helpers)
      end
    end

    # Add a load path for this specific Engine
    config.autoload_paths += %W( #{config.root}/lib )
    config.autoload_paths += %W( #{config.root}/app/helpers )
    config.autoload_paths += %W( #{config.root}/app/models )

    config.after_initialize do
      puts 'Initializing Railspress - GLOBAL'
      Railspress.GLOBAL.init

      # Register the default theme directory root
      puts 'Initializing Railspress - register_theme_directory...'
      Railspress::ThemeHelper.register_theme_directory('themes') # get_theme_root() does not work

    end
  end

  # this function maps the vars from your app into your engine
  def self.setup(&block)
    self.main_app_hook ||= Railspress::MainAppHook.new
    yield self

  end
end
