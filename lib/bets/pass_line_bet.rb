class PassLineBet < CrapsBet
  def name
    "Pass Line Bet"
  end

  def player_can_set_off?
    false
  end

  def validate(player_bet, amount)
    super
    raise "point must be off" if table.on?
  end

  def determine_outcome(player_bet)
    outcome = if table.front_line_winner? 
      Outcome::WIN
    elsif table.crapped_out?
      Outcome::LOSE
    elsif table.point_made?
      Outcome::WIN
    elsif table.seven_out?
      Outcome::LOSE
    else
      Outcome::NONE
    end
    outcome
  end
end
