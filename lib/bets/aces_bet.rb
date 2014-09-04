class AcesBet < PropositionBet
  def dice_matched_proposition?
    dice.rolled?(2)
  end
end
