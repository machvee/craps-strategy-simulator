module Craps
  class AceDeuceBet < PropositionBet
    def dice_matched_proposition?
      dice.rolled?(3)
    end
  end
end
