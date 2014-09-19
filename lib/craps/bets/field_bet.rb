module Craps
  class FieldBet < CrapsBet
    def name
      "Field Bet"
    end

    def outcome
      if dice.fields?
        Outcome::WIN
      else
        Outcome::LOSE
      end
    end
  end
end
