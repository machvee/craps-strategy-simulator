module Craps
  class ComeOddsBet < CrapsBet

    def name
      "Come Odds Bet #{number}"
    end

    def max_bet
      super * max_odds(number)
    end

    def bet_remains_after_win?
      false
    end

    def table_on_status
      # 
      # come bet odds are off when the table is off
      #
      table_state.off? ? OnStatus::OFF : OnStatus::ON
    end

    def validate(player_bet, bet_amount)
      super
      raise "you must have a Come Bet on #{number}" unless \
        player_bet.player.has_bet?(ComeBet, number)
    end

    def outcome
      #
      # odds bets are returned when the table is off so
      # if the number is made or seven out, the bet is returned
      # otherwise, if the player has it on, it wins when the number
      # is rolled and loses when a seven is rolled
      #
      if table_state.off? && (dice.seven? || rolled_the_number?)
        Outcome::RETURN
      elsif rolled_the_number?
        Outcome::WIN
      elsif table_state.seven_out?
        Outcome::LOSE
      else
        Outcome::NONE
      end
    end

    def self.gen_number_bets(table)
      CrapsDice::POINTS.map {|number| ComeOddsBet.new(table, number)}
    end
  end
end
