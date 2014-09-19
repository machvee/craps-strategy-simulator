class PropositionBet < CrapsBet

  def name
    self.class.name.titleize
  end

  def min_bet
    1
  end

  def dice_matched_proposition?
    # define in subclass
  end

  def outcome
    if dice_matched_proposition?
      Outcome::WIN
    else
      Outcome::LOSE
    end
  end
end
