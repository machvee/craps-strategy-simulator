require 'player_stats'

class Player
  attr_reader   :name
  attr_reader   :bets
  attr_reader   :stats
  attr_reader   :table
  attr_reader   :rail     # player account

  attr_accessor :bet_unit

  delegate :table_state, :config, to: :table
  delegate :bet_stats, :dice_stats, to: :stats

  def initialize(name, table, start_amount, bet_unit=nil)
    @bets = []
    @name = name
    @table = table
    valid_bet_unit?(bet_unit)
    @bet_unit = bet_unit || config.min_bet
    set_rail(start_amount)
    @stats = init_stats(start_amount)
  end

  def reset
    rail.reset
    stats.reset
  end

  def money
    rail.balance + wagers
  end

  def wagers
    bets.inject(0) {|s, b| s += b.amount}
  end

  def status(str, color=:white)
    table.status "  #{name} #{str} [#{money_status}]", color
  end

  def set_rail(start_amount)
    @rail = new_account(start_amount)
  end

  def new_account(start_amount)
    Account.new("#{name}'s rail", start_amount)
  end

  def new_bet(bet_box, amount)
    new_player_bet(bet_box, amount).tap do |bet|
      bets << bet
    end
  end

  def new_run(name, options={})
    Run.new(name, self, options.reverse_merge(start_bank: rail.start_balance, bet_unit: bet_unit))
  end

  def self.join_table(table, name, start_amount)
    #
    # create a new Player at a table
    #
    player = table.new_player(name, start_amount)
    player
  end

  def make_bet(bet_short_name, amount=nil, number=nil)
    #
    # e.g   make_bet('place', 12, 6)
    #    $12.00 Place bet on 6
    #
    amount ||= bet_unit
    bet_box = table.find_bet_box(bet_short_name, number)
    raise "#{name} needs to buy chips.  only $#{rail.balance} remains" unless can_bet?(amount)
    scaled_bet_amount = bet_box.craps_bet.scale_bet(amount)
    bet = bet_box.new_player_bet(self, scaled_bet_amount)
    bet
  end

  def ensure_bet(bet_short_name, amount=nil, number=nil)
    #
    # like make_bet, but if the identical bet already exists
    # just return.
    #
    amount ||= bet_unit
    bet_box = table.find_bet_box(bet_short_name, number)
    scaled_bet_amount = bet_box.craps_bet.scale_bet(amount)

    bet = find_bet(bet_short_name, number)
    unless bet.present? 
      bet = bet_box.new_player_bet(self, scaled_bet_amount)
    end
    bet
  end

  #
  # gen named methods for the player to make table bets
  # (skip PassOddsBet, we have a special convenience method for it)
  # use of named methods implies that if you already have the bet
  # for the same amount, no action is taken and no exception is
  # thrown
  #
  BetBox::NO_NUMBER_BETS.each do |no_number_bet|
    define_method(no_number_bet.short_name+'!') do |amount=nil|
      make_bet(no_number_bet.short_name, amount)
    end
    define_method(no_number_bet.short_name) do |amount=nil|
      ensure_bet(no_number_bet.short_name, amount)
    end
  end

  (BetBox::NUMBER_BETS - BetBox::MORPH_NUMBER_BETS).each do |number_bet|
    next if [PassOddsBet, ComeOddsBet].include?(number_bet) # special cases below
    define_method(number_bet.short_name+'!') do |number, amount=nil|
      make_bet(number_bet.short_name, amount, number)
    end
    define_method(number_bet.short_name) do |number, amount=nil|
      ensure_bet(number_bet.short_name, amount, number)
    end
  end

  #
  # pass_odds and come_odds bet helper are passed a multiple, 1 to
  # configured max odds for that number.  the default is the max odds
  # 
  def pass_odds!(multiple=config.max_odds(table_state.point))
    amount = base_pass_odds(multiple)
    make_bet('pass_odds', amount, table_state.point)
  end

  def pass_odds(multiple=config.max_odds(table_state.point))
    amount = base_pass_odds(multiple)
    ensure_bet('pass_odds', amount, table_state.point)
  end

  def come_odds!(number = table.last_roll, multiple=config.max_odds(number))
    amount = base_come_odds(number, multiple)
    make_bet('come_odds', amount, number)
  end

  def come_odds(number = table.last_roll, multiple=config.max_odds(number))
    amount = base_come_odds(number, multiple)
    ensure_bet('come_odds', amount, number)
  end

  def horn(high_number, amount)
    bets = CrapsBet.horn(high_number, amount)
    bets.each {|bet_name, amount_to_bet| ensure_bet(bet_name, amount_to_bet)}
  end

  def has_bet?(bet_short_name, number=nil)
    find_bet(bet_short_name, number).present?
  end

  def find_bet(bet_short_name, number=nil)
    bets.find {|b| b.matches?(bet_short_name, number)}
  end

  def take_down(player_bet)
    player_bet.return_bet
    player_bet.bet_box.remove_bet(player_bet)
  end

  def remove_from_player_bets(bet)
    bets.delete(bet)
  end

  def out?
    #
    # player ready to quit based on current state of bank?
    #
    bets.empty? && rail.balance == 0
  end

  def leave_table
    #
    # final stats tally, take down removable bets if any
    #
  end

  def money_status
    "$#{rail.balance} (#{stats.up_down})"
  end

  def to_s
    "#{name}: bet_unit: #{bet_unit}, rail: $#{rail.balance} (#{stats.up_down}), "\
    "wagers: $#{wagers}\nbets: #{formatted(bets)}"
  end

  def inspect
    to_s
  end

  def pay_any_commission(craps_bet, on_amount)
    commission = craps_bet.commission
    if commission > 0 && !table.config.pay_commission_on_win
      commission_amount = craps_bet.calculate_commission(on_amount)
      table.house.transfer_from(rail, commission_amount) if commission_amount > 0
    end
  end

  private

  def valid_multiple?(number, multiple)
    raise "multiple must be between 1 and #{config.max_odds(number)}" unless \
      multiple.between?(1, config.max_odds(number))
  end

  def valid_bet_unit?(bet_unit)
    raise "bet_unit must be at least #{config.min_bet} and at most #{config.max_bet}" if bet_unit.present? &&
      !bet_unit.between?(config.min_bet, config.max_bet)
  end

  def base_pass_odds(multiple)
    number = table_state.point
    raise "point must be established" unless table_state.on?
    pass_line_bet = find_bet('pass_line_point', number)
    raise "you must have a Pass Line Bet" if pass_line_bet.nil?
    valid_multiple?(number, multiple)
    amount = pass_line_bet.amount * multiple
    amount
  end

  def base_come_odds(number, multiple)
    raise "point must be established" unless table_state.on?
    come_bet = find_bet('come', number)
    raise "you must have a Come Bet on #{number}" if come_bet.nil?
    valid_multiple?(number, multiple)
    amount = come_bet.amount * multiple
    amount
  end

  def new_player_bet(bet_box, amount)
    PlayerBet.new(self, bet_box, amount)
  end

  def init_stats(start_amount)
    PlayerStats.new(self, start_amount)
  end

  def can_bet?(amount)
    rail.balance - amount > 0
  end

  def formatted(a)
    a.map {|e| e.inspect}.join("\n      ")
  end
end
