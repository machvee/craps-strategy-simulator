class BaseStrategy
  attr_reader   :table
  attr_reader   :player
  attr_reader   :place_sequence # order in which to make place bets when they're down
  attr_reader   :bet_makers

  delegate :table_state, to: :table

  def initialize(player)
    @player = player
    @table = player.table
    init_bet_makers
  end

  def name
    "base strategy" # override with name of strategy
  end

  def set
    # override this with logic that makes bets based on player state, bet history
    # and table state.  this creates bet_makers
  end

  def init_bet_makers
    @bet_makers = []
  end

  def retire
    init_bet_makers
  end

  def make_bets
    bet_makers.each { |maker| maker.make_bet }
  end

  #
  # example BetMaker builder calls
  #
  # pass_line
  # come_out
  # hard(8)
  # hard(10)
  # place_on(6)
  # place_on(8)
  # place_on(9)
  # buy_the(10)
  # buy_the(4)
  #
  #
  [[PlaceBet, :on], [BuyBet, :the], [[HardwaysBet, :hard], nil]].each do |b, prep|
    ap = Array(b) # [PlaceBet], or [HardwaysBet, :hard]
    bc = ap.first
    sn = ap.length > 1 ? ap.last.to_s : bc.short_name
    define_method(sn + (prep.present? ? "_#{prep}" : '')) do |number|
      install_bet(bc.short_name, number)
    end
  end

  BetBox::NO_NUMBER_BETS.each do |b|
    define_method(b.short_name) do
      install_bet(b.short_name)
    end
  end

  def bet_unit
    player.bet_unit
  end

  def all_bets_off
    #
    # TODO: iterate thru the player.player_bets and set the ones off that can
    # bet set off by the player
    #
    self
  end

  def when_tables_hot
    self
  end

  def when_tables_cold
    self
  end

  def when_tables_up_and_down
    self
  end

  def reset_bet_makers
    bet_makers.each {|bm| bm.reset}
  end

  def reset
    reset_bet_makers
  end

  def stats
    bet_makers.map {|b| b.to_s}.join("\n")
  end

  def install_bet(bet_short_name, number=nil)
    BetMaker.factory(player, bet_short_name, number).tap {|maker| bet_makers << maker}
  end

  #
  # convenient and common named bets and bet groupings
  #
  def all_the_hardways_for(amount)
    CrapsDice::HARDS.each {|n| hard(n).for(amount)}
  end

  def horn
    HornBetMaker.new(self)
  end

  def horn_high_yo
    horn.high(11)
  end

  def horn_high_aces
    horn.high(2)
  end

  def horn_high_ace_deuce
    horn.high(3)
  end

  def horn_high_twelve
    horn.high(12)
  end

  def across_for(amount)
    CrapsDice::POINTS.each {|n| place_on(n).for(amount)}
  end

  def across
    #
    # across for player configured bet_unit but not on point
    #
    CrapsDice::POINTS.each {|n| place_on(n)}
  end

  def six_and_eight(amount)
    [6,8].each do |n|
      place_on(n).for(amount)
    end
  end

end
