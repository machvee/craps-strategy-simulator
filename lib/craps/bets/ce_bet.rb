class CeBet < CrapsBet
  def name
    "C&E Bet"
  end

  def min_bet
    1
  end

  def outcome
    if dice.craps? || dice.eleven?
      Outcome::WIN
    else
      Outcome::LOSE
    end
  end

end
