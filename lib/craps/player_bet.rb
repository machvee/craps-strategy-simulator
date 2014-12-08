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

  CALLBACKS = [
    :win,
    :lose,
    :morph,
    :return
  ]
  attr_reader  :callbacks
  delegate :on, to: :callbacks

  MORPH_BET_SHORT_NAMES = BetBox::MORPH_NUMBER_BETS.map(&:short_name)

  delegate :craps_bet, to: :bet_box
  delegate :table, to: :player
  delegate :name, to: :craps_bet

  def initialize(player, bet_box, amount)
    @player = player
    @bet_box = bet_box
    @amount = amount
    @number = craps_bet.number
    @remove = false # used to clear losing bets at end of settling bets
    @bet_stat = set_bet_stat
    @callbacks = Callbacks.new(CALLBACKS)
    craps_bet.validate(self, amount)
    set_bet_on
    table.wagers.transfer_from(player.rail, amount)
    player.pay_any_commission(bet_box.craps_bet, amount)
    status verb, amount, :blue
  end

  def set_bet_stat
    player.bet_stats.stat_by_name(craps_bet.stat_name)
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

  def winning_bet
    bet_stat.won(made: amount, won: amount_won)

    player.rail.transfer_from(table.wagers, self.amount)
    player.rail.transfer_from(table.house, amount_won)

    status('wins', amount_won, :green)

    callbacks.invoke(:win, amount_won)
  end

  def losing_bet
    bet_stat.lost(made: amount, lost: amount)
    table.house.transfer_from(table.wagers, amount)
    status('loses', amount, :red)

    callbacks.invoke(:lose)
  end

  def return_bet
    return_wager
    status("returned", amount, :yellow)
    callbacks.invoke(:return)
  end

  def morph_bet
    callbacks.invoke(:morph)
  end

  def return_wager
    player.rail.transfer_from(table.wagers, self.amount)
  end

  def matches?(craps_bet_short_name, arg_number=nil)
    craps_bet.short_name == craps_bet_short_name && (number == arg_number || arg_number.nil?)
  end

  def to_s
    "$#{amount} #{craps_bet}"
  end

  def inspect
    to_s
  end

  private

  def amount_won
    @_amt_won ||= calculate_winnings
  end

  def calculate_winnings
    winnings = (amount/craps_bet.for_every) * craps_bet.pay_this

    if table.config.pay_commission_on_win && craps_bet.commission > 0
      winnings -= craps_bet.calculate_commission(amount)
    end
    winnings
  end

  def status(verbed, amount, color=:white)
    player.status "#{verbed} $#{amount} on #{craps_bet}", color
  end

  def verb
    if MORPH_BET_SHORT_NAMES.include?(craps_bet.short_name)
      'now has'
    else
      'puts'
    end
  end

  def set_bet_on
    @bet_off = false
  end

end
