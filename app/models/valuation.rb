class Valuation < ApplicationRecord
  include Entryable

  class << self
    def build_reconciliation_name(accountable_type)
      Valuation::Name.new("reconciliation", accountable_type).to_s
    end

    def build_opening_anchor_name(accountable_type)
      Valuation::Name.new("opening_anchor", accountable_type).to_s
    end

    def build_current_anchor_name(accountable_type)
      Valuation::Name.new("current_anchor", accountable_type).to_s
    end
  end

  # TODO: Remove this method when `kind` column is added to valuations table
  # This is a temporary implementation until the database migration is complete
  def kind
    "reconciliation"
  end
end
