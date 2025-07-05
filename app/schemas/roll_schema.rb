require 'dry-schema'

class RollSchema < Dry::Schema::JSON
  define do
    required(:roll).hash do
      required(:pins).value(:integer, gteq?: 0, lteq?: 10)
    end
  end
end 