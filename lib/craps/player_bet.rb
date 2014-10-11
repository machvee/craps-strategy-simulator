class PlayerBet
  attr_reader   :name
  attr_reader   :number
  attr_reader   :amount
  attr_reader   :player
  attr_reader   :craps_bet
  attr_reader   :bet_off
  attr_reader   :bet_stat

  attr_reader   :bet_box
  attr_accessor :remove

  delegate :craps_bet, to: :bet_box
  delegate :table, to: :player

  def initialize(player, bet_box, amount)
    @player = player
    @bet_box = bet_box
    @amount = amount
    @number = craps_bet.number
    @remove = false # used to clear losing bets at end of settling bets
    @bet_stat = set_bet_stat
    craps_bet.validate(self, amount)

    set_bet_on
  end

  def set_bet_stat
    player.bet_stats.stat_by_name(craps_bet.stat_name)
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

  def winning_bet(pay_this, for_every)
    winnings = (amount/for_every) * pay_this

    if table.config.pay_commission_on_win && craps_bet.commission > 0
      winnings -= craps_bet.calculate_commission(amount)
    end

    bet_stat.won(made: amount, won: winnings)

    player.rail.transfer_from(table.wagers, self.amount)
    player.rail.transfer_from(table.house, winnings)

    status('wins', winnings)
  end

  def losing_bet
    bet_stat.lost(made: amount, lost: amount)
    status('loses', amount)
    table.house.transfer_from(table.wagers, amount)
  end

  def return_bet
    player.rail.transfer_from(table.wagers, self.amount)
    status("returned", amount)
  end

  def morph_bet
    dest_bet_box = table.find_bet_box(craps_bet.morph_bet_name, table.last_roll)
    dest_bet_box.new_player_bet(player, amount)
  end

  def matches?(craps_bet_short_name, arg_number=nil)
    craps_bet.short_name == craps_bet_short_name && number == arg_number
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

  def status(verbed, amount)
    table.status "  #{player.name} #{verbed} $#{amount} on #{self}"
  end
end
