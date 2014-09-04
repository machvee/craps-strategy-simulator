class AnyCraps < PropositionBet
  def winning_bet?
    dice.craps?
  end
end
