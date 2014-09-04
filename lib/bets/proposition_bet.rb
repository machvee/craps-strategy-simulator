class PropositionBet < TableBet
  PROPOSITION_BETS = [
      AceDeuce,
      Aces,
      AnyCraps,
      AnySeven,
      Eleven,
      Twelve
  ]

  def name
    self.class.name.titleize + " Bet"
  end

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
    PROPOSITION_BETS.map { |bet_class| bet_class.new(table) } 
  end

end
