class CrapsBet
  attr_reader :number
  attr_reader :table

  module Outcome
    WIN=1    # player gets payoff
    LOSE=2   # house gets money
    RETURN=3 # return the bet to the player its was off by table rules
    NONE=4   # nothing happens
  end

  module OnStatus
    ON=1 # can be set by player or table.on?
    OFF=2 # can be set by player or table.on?
    FOLLOW=3 # follow table.on? and/or player.on_status
  end

  def initialize(table, number=nil)
    @table = table
    @number = number
  end

  def name
    raise "give the CrapsBet a name"
  end

  def bet_remains_after_win?
    true # convenience to keep bets going, but can be overridden with false (e.g. ComeBet, ComeOdds,etc)
  end

  def player_can_set_off?
    # overridden with false if bet is always on (e.g. PassLineBet, ComeOutBet, ComeBet)
    true
  end

  def table_on_status
    # default, bet is always on from the table rules
    # perspective, but can be overridden as FOLLOW to follow table.on/off? (e.g. PlaceBet, Hardways)
    OnStatus::ON
  end

  def on?
    case table_on_status
      when OnStatus::ON
        true
      when OnStatus::FOLLOW
        table.on?
    end
  end

  def payout
    #
    # e.g. [3,2]
    # pay 3 units, for every 2 unit bet
    #
    table.config.payoff_odds(self, number)
  end

  def made_the_number?
    table.last_roll == number
  end

  def to_s
    name
  end

  def inspect
    to_s
  end

  def validate(player_bet, bet_amount)
    #
    # validates that the bet is made at a legal time and bet_amount
    #
    #   1. not already made
    #   2. valid for on? off?
    #   3. doesn't exceed max odds multiplier
    #   4. doesn't exceed table maximum bet
    #
    # valid off? bet types
    #   PASS_LINE, HARDWAYS, CE
    # valid on? bet types
    #   all except PASS_LINE
    #   player must have number bet if making odds bet on PASS and COME
    #
    raise "you already have a #{name}" if player_bet.player.has_bet?(self.class, number)
    raise "you must bet at least $#{table.min_bet}" unless \
      bet_amount >= table.min_bet
    raise "bet amount would exceed maximium of $#{table.max_bet} for #{name}" if \
      bet_amount > table.max_bet
    for_every = payout.last
    raise "bet amount should be a multiple of #{for_every}" if 
      for_every > 1 && bet_amount % for_every != 0
    return
  end
end
