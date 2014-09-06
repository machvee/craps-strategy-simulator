class CeBet < TableBet
  def name
    "C&E Bet"
  end

  def min_bet
    1
  end

  def outcome
    additional_stats = {}
    result = if dice.craps? || dice.eleven?
      Outcome::WIN
    else
      Outcome::LOSE
    end
    [result, additional_stats]
  end

end
