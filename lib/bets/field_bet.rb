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

  def outcome
    additional_stats = {}
    result = if dice.fields?
      additional_stats = field_val_win_stat
      Outcome::WIN
    end
      Outcome::LOSE
    [result, additional_stats]
  end

  private

  def field_val_win_stat
    SPECIAL_STAT_NUMBERS.each {|v| 
      return {STAT_NAME_HASH[v] => OccurrenceStat::OCCURRED} if dice.rolled?(v)
    }
    {}
  end

end
