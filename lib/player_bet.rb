class PlayerBet
  attr_reader   :name
  attr_reader   :number
  attr_reader   :amount
  attr_reader   :player
  attr_reader   :table_bet
  attr_reader   :bet_off
  attr_accessor :remove

  delegate :table, to: :player

  def initialize(player, table_bet, amount)
    @player = player
    @amount = amount
    @table_bet = table_bet
    @number = table_bet.number
    @remove = false # used to clear losing bets at end of settling bets

    table_bet.validate(self, amount)
    table_bet.add_bet(self)

    set_bet_on
  end

  def press(additional_amount)
    new_amount = amount + additional_amount
    table_bet.validate(self, new_amount)
    @amount = new_amount
  end

  def stat_occurred(bet_stat_name)
    player.stats.occurred(bet_stat_name||table_bet.win_stat_name)
  end

  def stat_did_not_occur(bet_stat_name)
    player.stats.did_not_occur(bet_stat_name||table_bet.win_stat_name)
  end

  def stat_incr(bet_stat_name)
    player.stats.incr(bet_stat_name)
  end

  def back_on
    set_bet_on
  end

  def off
    raise "You can't set your #{table_bet} OFF" unless table_bet.player_can_set_off?
    @bet_off = true
  end

  def on?
    #
    # could be set off by player or by the rules of the table
    # TODO: hardways follow the table.on, but can be set on/off at any time by the player
    #
    !bet_off && table_bet.on?
  end

  def off?
    !on?
  end

  def pay_winning_bet
    pay_this, for_every = table.config.payoff_odds(table_bet, number)
    winnings = (amount/for_every) * pay_this
    player.to_rail(winnings)
    player.take_down(self) unless table_bet.bet_remains_after_win?
    winnings
  end

  def losing_bet
    player.from_wagers(amount)
    player.remove_bet(self)
  end

  def return_bet
    player.take_down
  end

  def morph_bet(new_bet_class, number=nil)
    #
    # good for turning ComeOutBet into a ComeBet(number)
    # or moving a Place Bet 6 to a Place Bet 8 after a Point of 6 is
    # established
    #
    craps.bet.remove_bet(self)
    @table_bet = find_table_bet(new_bet_class, number)
    table_bet.add_bet(self)
  end

  def remove_from_table
    table_bet.remove_bet(self)
  end

  def matches?(table_bet_class, arg_number=nil)
    table_bet.class == table_bet_class && number == arg_number
  end

  def to_s
    "$#{amount} #{table_bet}"
  end

  def inspect
    to_s
  end

  private

  def set_bet_on
    @bet_off = false
  end

end
