# frozen_string_literal: true

module Capistrano
  module Systemd
    module Sidekiq
      class Plugin < Capistrano::Plugin
        def set_defaults
          set_if_empty :sidekiq_env, -> { fetch(:stage) }
          set_if_empty :sidekiq_roles, -> { fetch(:sidekiq_processes).keys.map { |p| "sidekiq-#{p}" } }

          set_if_empty :sidekiq_pids_path, -> { File.join(shared_path, 'tmp', 'pids') }
          set_if_empty :sidekiq_pid, -> { File.join(fetch(:sidekiq_pids_path), 'sidekiq.pid') }

          set_if_empty :sidekiq_logs_path, -> { File.join(shared_path, 'log') }
          set_if_empty :sidekiq_access_log, -> { File.join(fetch(:sidekiq_logs_path), 'sidekiq.access.log') }
          set_if_empty :sidekiq_error_log, -> { File.join(fetch(:sidekiq_logs_path), 'sidekiq.error.log') }

          set_if_empty :sidekiq_configs_path, -> { File.join(current_path, 'config') }
          set_if_empty :sidekiq_config, -> { File.join(fetch(:sidekiq_configs_path), 'sidekiq.yml') }

          set_if_empty :sidekiq_init_system, :systemd
          set_if_empty :sidekiq_service_unit_user, :user # :system
          set_if_empty :sidekiq_lingering_user, nil
        end

        def define_tasks
          eval_rakefile File.expand_path('../tasks/sidekiq.rake', __FILE__)
        end

        def register_hooks
          after 'deploy:check', 'sidekiq:reload'
          after 'deploy:published', 'sidekiq:restart'
        end
      end
    end
  end
end
