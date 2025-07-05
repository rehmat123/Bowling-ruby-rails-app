require 'dry-schema'

RollSchema = Dry::Schema.JSON do
  required(:roll).hash do
    required(:pins).value(:integer, gteq?: 0, lteq?: 10)
  end
end 