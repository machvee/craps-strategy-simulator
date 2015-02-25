class RollStats < OccurrenceTableStatsCollection
  def initialize(name, options = {})
    super
  end

  def add_stats
    add [*CrapsDice::RANGE].map { |v|
      OccurrenceStat.new('rolled_%d' % v) {table.last_roll == v}
    }
  end
end
