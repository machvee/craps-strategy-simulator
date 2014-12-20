#
# for each shooter player, keep track of and record when shooter.done:
#   number_rolls_of_dice (hi lo avg)
#   number_of_points_won (hi lo avg)
#   number_of_front_line_winners
#   number_of_craps
#
class ShooterStats
  attr_reader :rolls
  attr_reader :points
  attr_reader :front_line_winners
  attr_reader :craps
  attr_reader :player

  def initialize(player)
    @player = player
    @rolls = Measure.new("rolls")
    @points = Measure.new("points")
    @front_line_winners = Measure.new("winners")
    @craps = Measure.new("craps")
  end
end
