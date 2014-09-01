class PlaceBet < CrapsBet

  def name
    "Place Bet #{number}"
  end

  def table_on_status
    OnStatus::FOLLOW # follows the table on/off status
  end

  def outcome(player_bet)
    result = if player_bet.off?
      Outcome::NONE
    elsif made_the_number?
      Outcome::WIN
    elsif state.seven_out?
      Outcome::LOSE
    else
      Outcome::NONE
    end
    result
  end

  def self.gen_number_bets(table)
    Table::POINTS.map {|number| PlaceBet.new(table, number)}
  end
end
