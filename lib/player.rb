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

  def initialize(name, table, amount, strategy_class=BasicStrategy)
    @bets = []
    @name = name
    @table = table
    @wagers = 0
    @rail = amount
    @start_rail = rail
    @stats = PlayerStats.new(self, rail)
    @strategy = strategy_class.new(self)
  end

  def self.join_table(table, name, start_amount)
    #
    # create a new Player at a table
    #
    player = table.new_player(name, start_amount)
    player
  end

  def make_bet(bet_class, amount, number=nil)
    #
    # e.g   make_bet(PlaceBet, 12, 6)
    #    $12.00 Place bet on 6
    #
    table_bet = table.find_table_bet(bet_class, number)
    amount ||= table_bet.min_bet
    raise "buy chips.  only $#{rail} remain" unless can_bet?(amount)
    bets << PlayerBet.new(self, table_bet, amount)
    rail_to_wagers(amount)
  end

  #
  # gen named methods for the player to make table bets
  # (skip PassOddsBet, we have a special convenience method for it)
  #
  Table::NO_NUMBER_BETS.each do |no_number_bet|
    define_method(no_number_bet.name.underscore) do |amount=nil|
      make_bet(no_number_bet, amount)
    end
  end

  Table::NUMBER_BETS.reject {|b| b == PassOddsBet}.each do |number_bet|
    define_method(number_bet.name.underscore) do |number, amount=nil|
      make_bet(number_bet, amount, number)
    end
  end

  def pass_odds_bet(amount=nil)
    pass_line_bet = find_bet(PassLineBet)
    raise "you don't have a pass line bet" if pass_line_bet.nil?
    amt = amount || (pass_line_bet.amount * config.max_odds(table_state.point))
    make_bet(PassOddsBet, amt, table_state.point)
  end

  def has_bet?(bet_class, number=nil)
    bets.any? {|b| b.matches?(bet_class, number)}
  end

  def find_bet(bet_class, number=nil)
    bets.find {|b| b.matches?(bet_class, number)}
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

  def take_down(bet)
    wagers_to_rail(bet.amount)
    remove_bet(bet)
  end

  def remove_bet(bet)
    bet.remove = true     # delays removal from player's array of bets to not break iterators
  end

  def remove_marked_bets
    #
    # because we can't delete bets from the bet arrays while iterating over them,
    # we delete bets marked as remove here
    #
    bets.each do |b|
      b.remove_from_table if b.remove # removes from table_bet square
    end
    bets.delete_if {|b| b.remove}
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

  def update_bet_stats_from_hash(stats_hash)
    stats.bet_stats.update_from_hash(stats_hash)
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
    up = 
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

  def can_bet?(amount)
    rail - amount > 0
  end
end
