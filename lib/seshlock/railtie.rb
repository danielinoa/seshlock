# frozen_string_literal: true

require "rails/railtie"

module Seshlock
  class Railtie < ::Rails::Railtie
    # Right now this is minimal; you can add initializers or logging later.
    #
    # For example, you could add dev-time sanity checks here:
    #
    # initializer "seshlock.sanity_checks" do
    #   ActiveSupport.on_load(:active_record) do
    #     # ...
    #   end
    # end
  end
end