require 'redmine'

Redmine::Plugin.register :redmine_sentry do
  name 'Redmine Sentry plugin'
  author 'Boris Gorbylev <ekho@ekho.name>'
  description 'This is a plugin for Redmine'
  version '0.0.1'
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

  if ENV.include?('SENTRY_DSN')
    host_name = nil
    ########
    # Direct Setting read is used for prevent of Setting object initialized before all plugins registred! Or later plugins will fail on tryin to read Setting.plugin_settings
    ########
    if ActiveRecord::Base.connection.table_exists?('settings')
      host_name = ActiveRecord::Base.connection.select_all("SELECT value FROM settings WHERE name='host_name'").first
    end

    Raven.configure do |config|
      config.server_name = host_name if host_name
      config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
      config.release = ENV['SENTRY_RELEASE'] if ENV.include?('SENTRY_RELEASE')
    end
  end

  unless ApplicationController.included_modules.include?(RedmineSentry::ApplicationControllerPatch)
    ApplicationController.send(:include, RedmineSentry::ApplicationControllerPatch)
  end
end