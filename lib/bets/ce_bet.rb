class CeBet < TableBet
  def name
    "C&E Bet"
  end

  def min_bet
    1
  end

  def outcome
    result = if dice.craps? || dice.eleven?
      Outcome::WIN
    else
      Outcome::LOSE
    end
    result
  end

end
