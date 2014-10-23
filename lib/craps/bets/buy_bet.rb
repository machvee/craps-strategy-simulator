class BuyBet < PlaceBet

  def name
    "Buy Bet #{number}"
  end

  def self.gen_number_bets(table)
    CrapsDice::POINTS.map {|number| BuyBet.new(table, number)}
  end
end
