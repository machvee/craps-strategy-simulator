class TrackingBet < PlayerBet

  def set_bet_stat
    table.tracking_bet_stats.stat_by_name(craps_bet.stat_name)
  end

  def winning_bet(pay_this, for_every)
    bet_stat.won
    return_bet
  end

  def losing_bet
    bet_stat.lost
  end

  def return_bet
    player.take_down(self)
  end

end
