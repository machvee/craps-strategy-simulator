module Craps
  class AnySevenBet < PropositionBet
    def dice_matched_proposition?
      dice.seven?
    end
  end
end
