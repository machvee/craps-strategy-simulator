class PassLineBet < CrapsBet

  def name
    "Pass Line Bet"
  end

  def player_can_set_off?
    false
  end

  def validate(player_bet, amount)
    super
    raise "point must be off" if table.on?
  end

  def determine_outcome(player_bet)
    outcome = if table.front_line_winner? 
      Outcome::WIN
    elsif table.crapped_out?
      Outcome::LOSE
    elsif table.point_made?
      Outcome::WIN
    elsif table.seven_out?
      Outcome::LOSE
    else
      Outcome::NONE
    end
    outcome
  end

  def bet_stats
    stat_table = [
      #  name           did_not_occur_when        occurred_when
      ['winners', Proc.new {table.off?},  Proc.new {table.front_line_winner?}],
      *CrapsDice::WINNERS.map {|v|
        ['winners_%d'%v, Proc.new {table.front_line_winner?}, Proc.new {table.front_line_winner?(v)}]
      },
      ['craps', Proc.new {table.off?}, Proc.new {table.crapped_out?}],
      *CrapsDice::CRAPS.map {|v| 
        ['craps_%d'%v, Proc.new {table.crapped_out?}, Proc.new {table.crapped_out?(v)}]
      },
      ['points', Proc.new {table.off?}, Proc.new {table.point_established?],
      *CrapsDice::POINTS.map { |v|
        ['points_%d', Proc.new {table.point_established?}, Proc.new {table.point_established?(v)}]
      },
      ['points_made', Proc.new {table.seven_out?}, Proce.new {table.point_made?}],
      *CrapsDice::POINTS.map {|v|
        ['points_made_%d'%v, Proc.new {table.point_made?}, Proce.new {table.point_made?(v)}]
      },
    ]
    stats_table.map { |stat_name, did_not_occur_proc, occurred_proc|
      OccurrenceStat.new(stat_name, did_not_occur_proc, &occurred_proc)
    }
  end

end
