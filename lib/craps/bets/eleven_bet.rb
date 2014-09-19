class ElevenBet < PropositionBet
  def dice_matched_proposition?
    dice.eleven?
  end
end
