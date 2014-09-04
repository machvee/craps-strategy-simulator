class AnySeven < PropositionBet
  def dice_matched_proposition?
    dice.seven?
  end
end
