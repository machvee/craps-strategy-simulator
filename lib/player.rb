require 'player_stats'

class Player
  attr_reader   :name
  attr_reader   :bets
  attr_reader   :stats
  attr_reader   :table
  attr_reader   :start_rail # amount started with
  attr_reader   :rail    # amount of money in rail
  attr_reader   :wagers  # amount of money bet

  delegate :table_state, to: :table

  def initialize(name, table, amount)
    @bets = []
    @name = name
    @table = table
    @wagers = 0
    @rail = amount
    @start_rail = rail
    @stats = PlayerStats.new(self, rail)
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
    # e.g   bet(PlaceBet, 12, 6)
    #    $12.00 Place bet on 6
    #
    raise "buy chips.  only $#{rail} remain" unless can_bet?(amount)
    bets << PlayerBet.new(self, bet_class, amount, number)
    rail_to_wagers(amount)
  end

  def pass_line_bet(amount=table.max_bet)
    make_bet(PassLineBet, amount)
  end

  def pl
    make_bet(PassLineBet, table.min_bet)
  end

  def po
    pass_odds_bet
  end

  def pass_odds_bet(amount=nil)
    pass_line_bet = find_bet(PassLineBet)
    raise "you don't have a pass line bet" if pass_line_bet.nil?
    amt = amount || (pass_line_bet.amount * table.max_odds(table_state.point))
    make_bet(PassOddsBet, amt, table_state.point)
  end

  def come_bet(amount=table.max_bet)
    make_bet(ComeOutBet, amount)
  end

  def come_odds_bet(number, amount=table.max_bet)
    make_bet(ComeOutBet, number, amount)
  end

  def place_bet(number, amount=table.max_bet)
    make_bet(PlaceBet, number, amount)
  end

  def hardways_bet(number, amount=table.max_bet)
    make_bet(HardwaysBet, number, amount)
  end

  def ce_bet(amount=table.max_bet)
    make_bet(CeBet, amount)
  end

  def has_bet?(bet_class, number=nil)
    bets.any? {|b| b.table_bet.class == bet_class && b.number == number}
  end

  def find_bet(bet_class, number=nil)
    bets.find {|b| b.table_bet.class == bet_class && b.number == number}
  end

  def rail_to_wagers(amount)
    @rail -= amount
    @wagers += amount
  end

  def wagers_to_rail(amount)
    #   2. player wagers back to rail (house return (or player take_down) bet)
    from_wagers(amount)
    to_rail(amount)
  end

  def from_wagers(amount)
    #   3. player wagers to house (lost bet)
    @wagers -= amount
  end

  def to_rail(amount)
    #   4. house to player rail (won bet)
    @rail += amount
  end

  def take_down(bet)
    wagers_to_rail(bet.amount)
    remove_bet(bet)
  end

  def loses(bet)
    from_wagers(bet.amount)
    remove_bet(bet)
  end

  def remove_bet(bet)
    bet.remove_from_table
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
