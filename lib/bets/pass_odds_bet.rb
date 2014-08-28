class PassOddsBet < CrapsBet

  def name
    "Pass Line Odds Bet #{number}"
  end

  def max_bet
    table.max_bet * table.max_odds(number)
  end

  def bet_remains_after_win?
    false
  end

  def player_on_status
    OnStatus::FOLLOW
  end

  def validate(player_bet, amount)
    super
    raise "point must be established" unless table.on?
    raise "you must have a Pass Line Bet" unless player_bet.player.has_bet?(PassLineBet)
  end

  def determine_outcome(player_bet)
    outcome = if player_bet.off?
      Outcome::NONE
    elsif table.point_made?
      Outcome::WIN
    elsif table.seven_out?
      Outcome::LOSE
    else
      Outcome::NONE
    end
    outcome
  end

  def self.gen_number_bets(table)
    Table::POINTS.map {|number| PassOddsBet.new(table, number)}
  end
end
