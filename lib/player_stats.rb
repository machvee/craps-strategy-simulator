class PlayerStats
  attr_reader   :player
  attr_reader   :start_amount
  attr_reader   :bet_stats

  delegate :table, to: :player

  def initialize(player, start_amount)
    @player = player
    @start_amount = start_amount
    @bet_stats = table.bet_stats.new_instance("#{player.name}'s bet stats")
  end

  def occurred(bet_stat_name)
    bet_stats.occurred(bet_stat_name)
  end

  def did_not_occur(bet_stat_name)
    bet_stats.did_not_occur(bet_stat_name)
  end

  def incr(bet_stat_name)
    bet_stats.incr(bet_stat_name)
  end
end
