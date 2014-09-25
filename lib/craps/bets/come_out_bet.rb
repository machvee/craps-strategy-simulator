class ComeOutBet < CrapsBet

  def initialize(table, number=nil)
    super
    morphs_to('come')
  end

  def name
    "Come Out Bet"
  end

  def validate(player_bet, bet_amount)
    super
    raise "point must be established" unless table_state.on?
  end

  def player_can_set_off?
    false
  end

  def outcome
    #
    # come out bet can be made when a point is established
    # if seven_yo? rolled, WIN
    # if craps? rolled, LOSE
    # if any POINTS rolled, morph the player_bet's craps_bet into a ComeBet(table, last_roll)
    if dice.seven_yo?
      Outcome::WIN
    elsif dice.craps?
      Outcome::LOSE
    elsif dice.points?
      Outcome::MORPH
    end
  end
end
