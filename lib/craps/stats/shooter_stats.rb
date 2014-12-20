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

  def initialize
    @rolls  = Measure.new("rolls per turn")
    @points = Measure.new("points made per turn")
  end

  def commit
    rolls.commit
    points.commit
  end

  def reset
    rolls.reset
    points.reset
  end

  def print
    puts @rolls.to_s
    puts @points.to_s
  end
end
