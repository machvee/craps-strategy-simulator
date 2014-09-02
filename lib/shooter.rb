class Shooter
  attr_reader   :table
  attr_reader   :player
  attr_reader   :last_shooter
  attr_accessor :dice
  attr_reader   :roll_stats # across all rolls on this table

  delegate :players, :dice_tray, to: :table

  def initialize(table)
    @table = table
    no_shooter
    @roll_stats = RollStats.new("dice", table)
  end

  def set
    #
    # if player.nil?, need to set the @player using
    # the last_shooter plus one player position, or back to 0
    # if last_shooter is nil or at end of players array
    #
    return unless player.nil?
    if !table.players_ready?
      @last_shooter = @player = nil
      raise "there are no players"
    else
      if last_shooter.nil?
        ns = 0
      else
        ns = players.index(last_shooter) + 1
        ns = 0 if (ns == players.length)
      end
      @last_shooter = @player = players[ns]
      @dice = dice_tray.take_dice
    end
    @player
  end

  def done
    return_dice
    @player = nil
  end

  def roll
    raise "no roll. a player to take the dice" if dice.nil?
    dice.roll.tap { |value|
      roll_stats.update
    }
  end

  def return_dice
    raise "no shooter" if dice.nil?
    dice_tray.return(dice)
    no_shooter
  end

  def reset_stats
    roll_stats.reset
  end

  def no_shooter
    @player = nil
  end

end
