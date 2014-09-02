class FieldBet < TableBet

  SPECIAL_STAT_NUMBERS=[2,12]
  STAT_NAME_HASH = Hash.new {|h,k| h[k] = 'field_%d' % k}

  def initialize(table, number=nil)
    super
    bet_stats.add SPECIAL_STAT_NUMBERS.map { |v|
      OccurrenceStat.new(STAT_NAME_HASH[v], Proc.new {dice.fields?}) {dice.rolled?(v)}
    }
  end

  def name
    "Field Bet"
  end

  def outcome(player_bet)
    result = if player_bet.off? 
      Outcome::NONE
    elsif dice.fields?
      update_field_val_win_stats(player_bet)
      Outcome::WIN
    end
      Outcome::LOSE
    result
  end

  private

  def update_field_val_win_stats(player_bet)
    SPECIAL_STAT_NUMBERS.each {|v| 
      if dice.rolled?(v)
        bet_stats.occurred(STAT_NAME_HASH[v]) 
        player_bet.stat_occurred(STAT_NAME_HASH[v])
        break
      end
    }
  end

end
