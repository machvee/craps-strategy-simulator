module Craps
  class PlayerBet
    attr_reader   :name
    attr_reader   :number
    attr_reader   :amount
    attr_reader   :player
    attr_reader   :craps_bet
    attr_reader   :bet_off
    attr_reader   :bet_stat
    attr_accessor :remove

    def initialize(player, craps_bet, amount)
      @player = player
      @amount = amount
      @craps_bet = craps_bet
      @number = craps_bet.number
      @remove = false # used to clear losing bets at end of settling bets
      @bet_stat = player.bet_stats.lkup(craps_bet.stat_name)
      craps_bet.validate(self, amount)

      set_bet_on
    end

    def press(additional_amount)
      new_amount = amount + additional_amount
      craps_bet.validate(self, new_amount)
      @amount = new_amount
    end

    def back_on
      set_bet_on
    end

    def off
      raise "You can't set your #{craps_bet} OFF" unless craps_bet.player_can_set_off?
      @bet_off = true
    end

    def on?
      #
      # could be set off by player or by the rules of the table
      # TODO: hardways follow the table.on, but can be set on/off at any time by the player
      #
      !bet_off && craps_bet.on?
    end

    def off?
      !on?
    end

    def pay_winning_bet(pay_this, for_every)
      winnings = (amount/for_every) * pay_this
      bet_stat.won(made: amount, won: winnings)
      player.to_rail(winnings)
      player.take_down(self) unless craps_bet.bet_remains_after_win?
      winnings
    end

    def losing_bet
      player.from_wagers(amount)
      bet_stat.lost(made: amount, lost: amount)
      player.remove_bet(self)
    end

    def return_bet
      player.take_down(self)
    end

    def matches?(craps_bet_class, arg_number=nil)
      craps_bet.class == craps_bet_class && number == arg_number
    end

    def to_s
      "$#{amount} #{craps_bet}"
    end

    def inspect
      to_s
    end

    private

    def set_bet_on
      @bet_off = false
    end
  end
end
