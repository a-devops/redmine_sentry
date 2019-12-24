require 'redmine'

Redmine::Plugin.register :redmine_sentry do
  name 'Redmine Sentry plugin'
  author 'Boris Gorbylev <ekho@ekho.name>'
  description 'This is a plugin for Redmine'
  version '1.1.1'
  url 'https://github.com/admitad-devops/redmine_sentry'
  author_url 'https://github.com/ekho'

  requires_redmine version_or_higher: '3.4'

  #menu :admin_menu, :redmine_sentry,
  #     { :controller => 'redmine_sentry', :action => 'index' },
  #     :caption => :label_redmine_sentry,
  #     :html => { :class => 'icon icon-redmine-sentry'},
  #     :if => Proc.new { User.current.admin? }

  #settings :default => { 'sentry_dsn' => '' }, :partial => 'redmine_sentry_settings'

  #should_be_disabled false if Redmine::Plugin.installed?(:easy_extensions)
end

Rails.application.config.to_prepare do
  require 'redmine_sentry'

  Rails.application.config.filter_parameters << :password
  Rails.application.config.filter_parameters << :password_confirmation

  sentry_config = {'dsn' => nil, 'release' => nil, 'environment' => ENV['RAILS_ENV'] || ENV['RACK_ENV'], 'server_name' => nil}
  sentry_config.merge!((Redmine::Configuration['sentry'] || {}).compact)
  sentry_config.merge!({'dsn' => ENV['SENTRY_DSN'], 'release' => ENV['SENTRY_RELEASE'], 'environment' => ENV['SENTRY_CURRENT_ENV'] || ENV['SENTRY_ENVIRONMENT'], }.compact)

  if sentry_config['server_name'].nil? && ActiveRecord::Base.connection.table_exists?('settings')
    ########
    # Direct Setting read is used for prevent of Setting object initialized before all plugins registred! Or later plugins will fail on tryin to read Setting.plugin_settings
    ########
    sentry_config['server_name'] = (ActiveRecord::Base.connection.select_all("SELECT value FROM settings WHERE name='host_name'").first || {'value': nil})['value']
  end

  Rails.logger.debug("[redmine_sentry] config: #{sentry_config.inspect}")

  if sentry_config['dsn']
    Raven.configure do |config|
      config.dsn = sentry_config.fetch('dsn')
      config.server_name = sentry_config.fetch('server_name')
      config.current_environment = sentry_config.fetch('environment')
      config.release = sentry_config.fetch('release')

      config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
    end
  end

  unless ApplicationController.included_modules.include?(RedmineSentry::ApplicationControllerPatch)
    ApplicationController.send(:include, RedmineSentry::ApplicationControllerPatch)
  end
end