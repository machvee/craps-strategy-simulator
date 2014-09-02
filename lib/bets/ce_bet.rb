class CeBet < TableBet
  def name
    "C&E Bet"
  end

  def player_can_set_off?
    false
  end

  def outcome(player_bet)
    result = if dice.craps? || dice.eleven?
      Outcome::WIN
    else
      Outcome::LOSE
    end
    result
  end

end
