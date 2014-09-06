class TableBet
  attr_reader :number
  attr_reader :table
  attr_reader :player_bets

  delegate :dice, :config, :table_state, :bet_stats,  to: :table

  module Outcome
    WIN=1    # player gets payoff
    LOSE=2   # house gets money
    RETURN=3 # return the bet to the player its was off by table rules
    COME=4   # come out bet is moved to the point numbered come bet 
    NONE=5   # nothing happens
  end

  module OnStatus
    ON=1 # can be set by player or table.on?
    OFF=2 # can be set by player or table.on?
    FOLLOW=3 # follow table.on? and/or player.on_status
  end

  def initialize(table, number=nil)
    @table = table
    @number = number
    @player_bets = []
    bet_stats.add OccurrenceStat.new(win_stat_name)
  end

  def add_bet(player_bet)
    player_bets << player_bet
  end

  def remove_bet(player_bet)
    player_bets.delete(player_bet)
  end

  def name
    raise "give the TableBet a name"
  end

  def determine_outcome
    result, stats = outcome
    case result
      when Outcome::WIN
        stats.merge!(win_stat)
      when Outcome::LOSE
        stats.merge!(lose_stat)
    end
    [result, stats]
  end

  def outcome
    # subclass override and uses table state and dice value to
    # determine if the bet won or lost
    # return [Outcome::XXXX, {custom_stat_name => OccurrenceStat::OCCCURRED|OccurrenceStat::DID_NOT_OCCUR, ...}]
  end

  def bet_remains_after_win?
    true # convenience to keep bets going, but can be overridden with false
         # (e.g. ComeBet, ComeOdds,etc)
  end

  def player_can_set_off?
    # overridden with false if bet is always on (e.g. PassLineBet, ComeOutBet, ComeBet)
    true
  end

  def table_on_status
    # default, bet is always on from the table rules
    # perspective, but can be overridden as FOLLOW to follow table.on/off?
    # (e.g. PlaceBet, Hardways)
    OnStatus::ON
  end

  def on?
    case table_on_status
      when OnStatus::ON
        true
      when OnStatus::FOLLOW
        table_state.on?
    end
  end

  def payout
    #
    # e.g. [3,2]
    # pay 3 units, for every 2 unit bet
    #
    config.payoff_odds(self, number)
  end

  def min_bet
    config.min_bet
  end

  def max_bet
    config.max_bet
  end

  def rolled_the_number?
    dice.rolled?(number)
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
    raise "you must bet at least $#{min_bet}" unless \
      bet_amount >= min_bet
    raise "bet amount would exceed maximium of $#{max_bet} for #{name}" if \
      bet_amount > max_bet
    for_every = payout.last
    raise "bet amount should be a multiple of #{for_every}" if 
      for_every > 1 && bet_amount % for_every != 0
    return
  end

  def win_stat
    {win_stat_name => OccurrenceStat::OCCURRED}
    # bet_stats.occurred(win_stat_name)
  end

  def lose_stat
    {win_stat_name => OccurrenceStat::DID_NOT_OCCUR}
    # bet_stats.did_not_occur(win_stat_name)
  end

  def win_stat_name
    @_wsn ||= stat_name
  end

  private

  def stat_name(suffix='')
    bet_class_name = self.class.name.underscore.gsub(/_bet/,'')
    number_part_if_any = number.nil? ? '' : "_#{number}"
    s_name = bet_class_name + number_part_if_any + suffix
    s_name
  end
end
