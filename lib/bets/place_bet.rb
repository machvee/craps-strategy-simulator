class PlaceBet < TableBet

  def name
    "Place Bet #{number}"
  end

  def min_bet
    pay_this, for_every = config.payoff_odds(self, number)
    (super.to_f / for_every).ceil * for_every
  end

  def table_on_status
    OnStatus::FOLLOW # follows the table on/off status
  end

  def outcome(player_bet)
    result = if player_bet.off?
      Outcome::NONE
    elsif made_the_number?
      Outcome::WIN
    elsif table_state.seven_out?
      Outcome::LOSE
    else
      Outcome::NONE
    end
    result
  end

  def self.gen_number_bets(table)
    CrapsDice::POINTS.map {|number| PlaceBet.new(table, number)}
  end
end
