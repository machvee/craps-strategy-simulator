module Craps
  class PlayerStats
    attr_reader   :player
    attr_reader   :start_amount
    attr_reader   :bet_stats
    attr_reader   :roll_stats # when the player is the shooter

    delegate :table, to: :player

    def initialize(player, start_amount)
      @player = player
      @start_amount = start_amount
      @bet_stats = table.player_bet_stats.new_child_instance("#{player.name}'s bet stats")
      @roll_stats = table.shooter.roll_stats.new_child_instance("#{player.name}'s shooter stats")
    end
  end
end
