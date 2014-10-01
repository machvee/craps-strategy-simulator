class TrackingPlayer < Player

  def initialize(table)
    super('tracking player', table, 0, nil, CoverAllBetsStrategy)
  end

  def rail_to_wagers(amount); end

  def wagers_to_rail(amount); end

  def from_wagers(amount); end

  def to_rail(amount); end

  def out?
    false
  end

  def to_s
    "#{name}:\nbets: #{formatted(bets)}"
  end

  private

  def can_bet?(amount)
    true
  end

  def init_stats(start_bank)
    TrackingStats.new(self)
  end

  def new_player_bet(bet_box, amount)
    TrackingBet.new(self, bet_box, amount)
  end

end
