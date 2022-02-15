# frozen_string_literal: true

require_relative "sidekiq/version"

require_relative "sidekiq/plugin"
require_relative "sidekiq/dsl"

module Capistrano
  module Systemd
    module Sidekiq
    end
  end
end
