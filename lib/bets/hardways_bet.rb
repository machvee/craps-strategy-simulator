class HardwaysBet < CrapsBet

  def name
    "Hardways Bet #{number}"
  end

  def table_on_status
    OnStatus::FOLLOW # follows the table on/off status
  end

  def outcome(player_bet)
    result = if player_bet.off?
      Outcome::NONE
    elsif made_the_number? && dice.hard?(number)
      Outcome::WIN
    elsif dice.seven? || (made_the_number? && dice.easy?(number))
      Outcome::LOSE
    else
      Outcome::NONE
    end
    result
  end

  def bet_stats
    # OccurrenceStat.new('hard_%d' % number, Proc.new {dice.rolled?(number)}) {dice.hard?(number)}
  end

  def self.gen_number_bets(table)
    Table::HARDS.map {|number| HardwaysBet.new(table, number)}
  end

end
