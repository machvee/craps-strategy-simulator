class TrackingStats
  attr_reader   :tracking_player
  attr_reader   :bet_stats

  def initialize(player)
    @tracking_player = player
    @bet_stats = StatsCollection.new("tracking bet stats")
  end
end
