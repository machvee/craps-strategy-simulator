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

  attr_accessor :maker # the BetMaker that created us, if 

  delegate :craps_bet, to: :bet_box
  delegate :table, to: :player

  def initialize(player, bet_box, amount)
    @player = player
    @bet_box = bet_box
    @amount = amount
    @number = craps_bet.number
    @remove = false # used to clear losing bets at end of settling bets
    @bet_stat = set_bet_stat
    @maker = nil
    craps_bet.validate(self, amount)

    set_bet_on

    status 'puts', @amount
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

  #
  # press or reduce
  #
  def change_amount(new_amount)
    direction = new_amount - amount
    delta = direction.abs
    if direction < 0
      #
      # reduce the bet amound put the difference back
      # in player rail
      #
      player.rail.transfer_from(table.wagers, delta)
      @amount -= delta
      status 'reduced bet to', @amount
    elsif delta > 0
      @amount += delta
      craps_bet.validate_amount(self, amount)
      #
      # inrease the bet, moving the difference from the
      # player rail to the table wagers
      #
      table.wagers.transfer_from(player.rail, delta)
      status 'pressed bet to', amount
      player.pay_any_commission(craps_bet, delta)
    end
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
    number = table.last_roll
    point_bet_box = table.find_bet_box(craps_bet.morph_bet_name, number)
    point_bet = point_bet_box.new_player_bet(player, amount)
    point_bet.maker = maker

    if maker.present? && maker.make_odds_bet
      #
      # build an odds bet based on the BetMaker odds multiples
      #
      odds_bet_box = table.find_bet_box(point_bet_box.craps_bet.odds_bet_short_name, number)
      odds_bet = odds_bet_box.new_player_bet(player, maker.odds_multiple[number] * maker.start_amount)
      odds_bet.maker = maker
    end
    point_bet
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

  def set_bet_on
    @bet_off = false
  end

  def status(verbed, amount)
    player.status "#{verbed} $#{amount} on #{craps_bet}"
  end
end
