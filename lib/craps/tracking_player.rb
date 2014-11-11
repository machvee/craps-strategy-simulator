class TrackingPlayer < Player

  TRACKING_STRATEGY=CoverAllBetsStrategy

  def initialize(table)
    super('tracking player', table, 0, nil)
  end

  def out?
    false
  end

  def to_s
    "#{name}:\nbets: #{formatted(bets)}"
  end

  def status(str, color); end # quiet

  private

  def can_bet?(amount)
    true
  end

  def new_account(start_amount)
    TrackingAccount.new('tracking account', start_amount)
  end

  def init_stats(start_bank)
    TrackingStats.new(self)
  end

  def new_player_bet(bet_box, amount)
    TrackingBet.new(self, bet_box, amount)
  end

end
