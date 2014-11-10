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
  delegate :name, to: :craps_bet

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
    table.wagers.transfer_from(player.rail, amount)
    player.pay_any_commission(bet_box.craps_bet, amount)
    status 'puts', amount, :blue
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

  def winning_bet(pay_this, for_every)
    winnings = (amount/for_every) * pay_this

    if table.config.pay_commission_on_win && craps_bet.commission > 0
      winnings -= craps_bet.calculate_commission(amount)
    end

    bet_stat.won(made: amount, won: winnings)
    maker_stat_won(winnings)

    player.rail.transfer_from(table.wagers, self.amount)
    player.rail.transfer_from(table.house, winnings)

    status('wins', winnings, :green)
  end

  def losing_bet
    bet_stat.lost(made: amount, lost: amount)
    table.house.transfer_from(table.wagers, amount)
    status('loses', amount, :red)
  end

  def return_bet
    return_wager
    status("returned", amount, :yellow)
  end

  def return_wager
    player.rail.transfer_from(table.wagers, self.amount)
  end

  def morph_bet
    #
    # this turns a pass_line bet or come_out bet into a 
    # pass_line_point bet or come_bet and will make an
    # accompanying odds bet as the bet maker (if any) defined.
    #
    number = table.last_roll
    point_bet_box = table.find_bet_box(craps_bet.morph_bet_name, number)
    point_bet = point_bet_box.new_player_bet(player, amount)
    point_bet.maker = maker

    if maker.present? && maker.make_odds_bet
      maker.create_odds_bet(point_bet_box.craps_bet, amount, number)
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

  def maker_stat_won(winnings)
    return unless maker.present?
    maker.stats.winner(winnings)
  end

  def status(verbed, amount, color=:white)
    player.status "#{verbed} $#{amount} on #{craps_bet}", color
  end

  def set_bet_on
    @bet_off = false
  end

end
