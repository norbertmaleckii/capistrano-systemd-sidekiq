# frozen_string_literal: true

namespace :sidekiq do
  desc 'Reload sidekiq'
  task :reload do
    on roles fetch(:sidekiq_roles) do |role|
      sidekiq_switch_user(role) do
        sidekiq_each_process(role) do |process_name, options, index|
          if fetch(:sidekiq_service_unit_user) == :system
            execute :sudo, :systemctl, "reload", process_name, raise_on_non_zero_exit: false
          else
            execute :systemctl, "--user", "reload", process_name, raise_on_non_zero_exit: false
          end
        end
      end
    end
  end

  desc 'Restart sidekiq'
  task :restart do
    on roles fetch(:sidekiq_roles) do |role|
      sidekiq_switch_user(role) do
        sidekiq_each_process(role) do |process_name, options, index|
          if fetch(:sidekiq_service_unit_user) == :system
            execute :sudo, :systemctl, "restart", process_name
          else
            execute :systemctl, "--user", "restart", process_name
          end
        end
      end
    end
  end

  desc 'Stop sidekiq'
  task :stop do
    on roles fetch(:sidekiq_roles) do |role|
      sidekiq_switch_user(role) do
        sidekiq_each_process(role) do |process_name, options, index|
          if fetch(:sidekiq_service_unit_user) == :system
            execute :sudo, :systemctl, "stop", process_name
          else
            execute :systemctl, "--user", "stop", process_name
          end
        end
      end
    end
  end

  desc 'Start sidekiq'
  task :start do
    on roles fetch(:sidekiq_roles) do |role|
      sidekiq_switch_user(role) do
        sidekiq_each_process(role) do |process_name, options, index|
          if fetch(:sidekiq_service_unit_user) == :system
            execute :sudo, :systemctl, 'start', process_name
          else
            execute :systemctl, '--user', 'start', process_name
          end
        end
      end
    end
  end

  desc 'Install systemd sidekiq service'
  task :install do
    on roles fetch(:sidekiq_roles) do |role|
      sidekiq_switch_user(role) do
        sidekiq_each_process(role) do |process_name, options, index|
          sidekiq_create_systemd_template(process_name, options, index)

          if fetch(:sidekiq_service_unit_user) == :system
            execute :sudo, :systemctl, "enable", process_name
          else
            execute :systemctl, "--user", "enable", process_name
            execute :loginctl, "enable-linger", fetch(:sidekiq_lingering_user) if fetch(:sidekiq_lingering_user)
          end
        end
      end
    end
  end

  desc 'UnInstall systemd sidekiq service'
  task :uninstall do
    on roles fetch(:sidekiq_roles) do |role|
      sidekiq_switch_user(role) do
        sidekiq_each_process(role) do |process_name, options, index|
          if fetch(:sidekiq_service_unit_user) == :system
            execute :sudo, :systemctl, "disable", process_name
          else
            execute :systemctl, "--user", "disable", process_name
          end

          execute :rm, '-f', File.join(fetch_systemd_unit_path, process_name)
        end
      end
    end
  end

  # TODO: Make it working after multi server multi process adjustment
  # desc 'Generate service_locally'
  # task :generate_service_locally do
  #   run_locally do
  #     sidekiq_each_process(role) do |process_name, options, index|
  #       File.write("tmp/#{process_name}.service", sidekiq_compiled_service_template(process_name, options, index))
  #     end
  #   end
  # end
end
