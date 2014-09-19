module Craps
  class AnyCrapsBet < PropositionBet
    def dice_matched_proposition?
      dice.craps?
    end
  end
end
