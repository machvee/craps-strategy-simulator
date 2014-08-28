class ComeOutBet < CrapsBet
  def name
    "Come Out Bet"
  end

  def validate(player_bet, bet_amount)
    super
    raise "point must be established" unless table.on?
  end

  def player_can_set_off?
    false
  end

  def determine_outcome(player_bet)
    #
    # come out bet can be made when a point is established
    # if seven_yo? rolled, WIN
    # if craps? rolled, LOSE
    # if any POINTS rolled, morph the player_bet's craps_bet into a ComeBet(table, last_roll)
    outcome = if table.seven_yo?
      Outcome::WIN
    elsif table.craps?
      Outcome::LOSE
    elsif table.points?
      player_bet.morph_bet(ComeBet, table.last_roll)
      Outcome::NONE
    else
      Outcome::NONE
    end
    outcome
  end
end
