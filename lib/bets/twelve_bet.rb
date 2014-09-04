class TwelveBet < PropositionBet
  def dice_matched_proposition?
    dice.rolled?(12)
  end
end
