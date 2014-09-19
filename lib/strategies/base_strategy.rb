module Craps
  class BaseStrategy
    attr_reader :table
    attr_reader :player

    delegate :table_state, to: :table

    def initialize(player)
      @player = player
      @table = player.table
    end

    def make_bets
      # override this with logic that makes bets based on player state, bet history
      # and table state
    end
  end
end
