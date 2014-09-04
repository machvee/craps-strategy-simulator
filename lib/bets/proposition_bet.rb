class PropositionBet < TableBet
  def min_bet
    1
  end

  def dice_matched_proposition?
    # define in subclass
  end

  def outcome(player_bet)
    result = if dice_matched_proposition?
      Outcome::WIN
    else
      Outcome::LOSE
    end
    result
  end

  def self.gen_bets(table)
    [
      AnyCraps,
      AnySeven,
      Eleven,
      AceDeuce,
      Aces,
      Twelve
    ].map do |bet_class|
      bet_class.new(table)
    end
  end

end
