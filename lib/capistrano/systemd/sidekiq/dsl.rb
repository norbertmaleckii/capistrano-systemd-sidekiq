# frozen_string_literal: true

module Capistrano
  module Systemd
    module Sidekiq
      module DSL
        def sidekiq_each_process(role)
          fetch(:sidekiq_processes).select { |k, _v| role.roles.to_a.map(&:to_s).include?("sidekiq-#{k}") }.each do |process_name, options_for_all|
            set(:sidekiq_current_process_name, process_name)

            options_for_all.each_with_index do |options, index|
              set(:sidekiq_current_options, options)

              yield "sidekiq-#{process_name}-#{index}", options, index
            end
          end
        end

        def sidekiq_create_systemd_template(process_name, options, index)
          systemd_path = fetch_sidekiq_systemd_unit_path

          if fetch(:sidekiq_service_unit_user) == :user
            execute :mkdir, "-p", systemd_path
          end

          ctemplate = sidekiq_compiled_service_template(process_name, options, index)
          upload!(StringIO.new(ctemplate), "/tmp/#{process_name}.service")

          if fetch(:sidekiq_service_unit_user) == :system
            execute :sudo, :mv, "/tmp/#{process_name}.service", "#{systemd_path}/#{process_name}.service"
            execute :sudo, :systemctl, "daemon-reload"
          else
            execute :mv, "/tmp/#{process_name}.service", "#{systemd_path}/#{process_name}.service"
            execute :systemctl, "--user", "daemon-reload"
          end
        end

        def sidekiq_compiled_service_template(process_name, options, index)
          args = []
          args.push "--pidfile #{fetch(:sidekiq_pid)}"
          args.push "--environment #{fetch(:sidekiq_env)}"
          args.push "--logfile #{fetch(:sidekiq_access_log)}"
          args.push "--concurrency #{fetch(:sidekiq_concurrency)}" if fetch(:sidekiq_concurrency)
          args.push options

          search_paths = [
            File.expand_path(
                File.join(*%w[.. templates sidekiq.service.erb]),
                __FILE__
            ),
          ]
          template_path = search_paths.detect { |path| File.file?(path) }
          template = File.read(template_path)

          ERB.new(template).result(binding)
        end

        def sidekiq_switch_user(role)
          su_user = sidekiq_user

          if su_user != role.user
            yield
          else
            as su_user do
              yield
            end
          end
        end

        def sidekiq_user
          fetch(:sidekiq_user, fetch(:run_as))
        end

        def fetch_sidekiq_systemd_unit_path
          if fetch(:sidekiq_service_unit_user) == :system
            "/etc/systemd/system/"
          else
            home_dir = capture(:pwd)

            File.join(home_dir, ".config", "systemd", "user")
          end
        end
      end
    end
  end
end

extend Capistrano::Systemd::Sidekiq::DSL

SSHKit::Backend::Local.module_eval do
  include Capistrano::Systemd::Sidekiq::DSL
end

SSHKit::Backend::Netssh.module_eval do
  include Capistrano::Systemd::Sidekiq::DSL
end
