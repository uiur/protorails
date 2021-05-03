require "protorails/engine"

module Protorails
  def self.setup
    yield self.config
  end
end
