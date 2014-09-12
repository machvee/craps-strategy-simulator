class FieldBet < TableBet

  SPECIAL_STAT_NUMBERS=[2,12]
  STAT_NAME_HASH = Hash.new {|h,k| h[k] = 'field_%d' % k}

  def initialize(table, number=nil)
    super
    bet_stats.add SPECIAL_STAT_NUMBERS.map { |v|
      OccurrenceStat.new(STAT_NAME_HASH[v])
    }
  end

  def name
    "Field Bet"
  end

  def outcome
    additional_stats = {}
    result = if dice.fields?
      additional_stats = special_win_stat
      Outcome::WIN
    else
      Outcome::LOSE
    end
    [result, additional_stats]
  end

  private

  def special_win_stat
    additional_stats = {}
    SPECIAL_STAT_NUMBERS.each do |v| 
      if dice.rolled?(v)
        additional_stats = {STAT_NAME_HASH[v] => OccurrenceStat::WON}
        break
      end
    end
    additional_stats
  end

end
