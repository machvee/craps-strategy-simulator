require 'player_stats'

class Player
  attr_reader   :name
  attr_reader   :bets
  attr_reader   :stats
  attr_reader   :table
  attr_reader   :start_rail # amount started with
  attr_reader   :rail    # amount of money in rail
  attr_reader   :wagers  # amount of money bet
  attr_accessor :strategy

  delegate :table_state, :config, to: :table
  delegate :bet_stats, :roll_stats, to: :stats

  def initialize(name, table, amount, strategy_class=BasicStrategy)
    @bets = []
    @name = name
    @table = table
    @wagers = 0
    @rail = amount
    @start_rail = rail
    @stats = init_stats
    @strategy = strategy_class.new(self)
  end

  def new_bet(bet_box, amount)
    PlayerBet.new(self, bet_box, amount)
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
    bet_box = table.find_bet_box(bet_short_name, number)
    amount ||= bet_box.craps_bet.min_bet
    raise "#{name} needs to buy chips.  only $#{rail} remains" unless can_bet?(amount)
    bets << bet_box.new_player_bet(self, amount)
    rail_to_wagers(amount)
  end

  def ensure_bet(bet_short_name, amount=nil, number=nil)
    #
    # like make_bet, but if the identical bet already exists
    # just return.  Call this when you want to ensure you have
    # the bet covered, but you may have it covered already
    # if you have it covered but at a different amount, you
    # may want to press/reduce the bet instead
    #
    bet_box = table.find_bet_box(bet_short_name, number)
    amount ||= bet_box.craps_bet.min_bet
    bet = find_bet(bet_short_name, number)
    return if bet.present? && bet.amount == amount

    make_bet(bet_short_name, amount, number)
  end


  #
  # gen named methods for the player to make table bets
  # (skip PassOddsBet, we have a special convenience method for it)
  # use of named methods implies that if you already have the bet
  # for the same amount, no action is taken and no exception is
  # thrown
  #
  Table::NO_NUMBER_BETS.each do |no_number_bet|
    define_method(no_number_bet.short_name+'!') do |amount=nil|
      make_bet(no_number_bet.short_name, amount)
    end
    define_method(no_number_bet.short_name) do |amount=nil|
      ensure_bet(no_number_bet.short_name, amount)
    end
  end

  (Table::NUMBER_BETS - Table::MORPH_NUMBER_BETS).each do |number_bet|
    next if [PassOddsBet, ComeOddsBet].include?(number_bet) # special cases below
    define_method(number_bet.short_name+'!') do |number, amount=nil|
      make_bet(number_bet.short_name, amount, number)
    end
    define_method(number_bet.short_name) do |number, amount=nil|
      ensure_bet(number_bet.short_name, amount, number)
    end
  end

  def pass_odds!(amount=nil)
    amt = base_pass_odds(amount)
    make_bet('pass_odds', amt, table_state.point)
  end

  def pass_odds(amount=nil)
    amt = base_pass_odds(amount)
    ensure_bet('pass_odds', amt, table_state.point)
  end

  def come_odds!(number, amount=nil)
    amt = base_come_odds(number, amount)
    make_bet('come_odds', amt, number)
  end

  def come_odds(number, amount=nil)
    amt = base_come_odds(number, amount)
    ensure_bet('come_odds', amt, number)
  end

  def has_bet?(bet_short_name, number=nil)
    find_bet(bet_short_name, number).present?
  end

  def find_bet(bet_short_name, number=nil)
    #
    # helper for pass_line_point and come bets, if number is nil, assume
    # table_state.point
    #
    number = table_state.point if bet_short_name == 'pass_line_point' && number.nil?
    bets.find {|b| b.matches?(bet_short_name, number)}
  end

  def rail_to_wagers(amount)
    @rail -= amount
    @wagers += amount
  end

  def wagers_to_rail(amount)
    #   player wagers back to rail (house return (or player take_down) bet)
    from_wagers(amount)
    to_rail(amount)
  end

  def from_wagers(amount)
    #   player wagers to house (lost bet)
    @wagers -= amount
  end

  def to_rail(amount)
    #   house to player rail (won bet)
    @rail += amount
  end

  def take_down(player_bet)
    wagers_to_rail(player_bet.amount)
  end

  def remove_from_player_bets(bet)
    bets.delete(bet)
  end

  def out?
    #
    # player ready to quit based on current state of bank?
    #
    bets.empty? && rail == 0
  end

  def leave_table
    #
    # final stats tally, take down removable bets if any
    #
  end

  def play_strategy
    #
    # here's where the configurable player strategy comes in
    #
    #  e.g.  when table is off?, make a 10 pass_line bet and a 2 CE
    #        when point is established, make full odds bet on that number, and a 10 come bet
    #        make come odds bet and place bet on any uncovered 6 or 8
    #        on place winners, have a bet progression strategy
    #
    strategy.make_bets
  end

  def to_s
    "#{name}: rail: $#{rail} (#{up_down}), wagers: $#{wagers}, bets: #{bets}"
  end

  def inspect
    to_s
  end

  def up_down
    ud = (rail + wagers) - start_rail
    sign = ud == 0 ? '' : (ud < 0 ? '-' : '+')
    "#{sign}$#{ud.abs}"
  end

  private

  def base_pass_odds(amount)
    raise "point must be established" unless table_state.on?
    pass_line_bet = find_bet('pass_line_point', table_state.point)
    raise "you must have a Pass Line Bet" if pass_line_bet.nil?
    amt = amount || (pass_line_bet.amount * config.max_odds(table_state.point))
    amt
  end

  def base_come_odds(number, amount)
    raise "point must be established" unless table_state.on?
    come_bet = find_bet('come', number)
    raise "you must have a Come Bet on #{number}" if come_bet.nil?
    amt = amount || (come_bet.amount * config.max_odds(number))
    amt
  end

  def init_stats
    PlayerStats.new(self, rail)
  end

  def can_bet?(amount)
    rail - amount > 0
  end
end
