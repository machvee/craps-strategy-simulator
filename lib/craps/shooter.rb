class Shooter
  attr_reader   :table
  attr_reader   :player
  attr_reader   :last_shooter
  attr_accessor :dice
  attr_reader   :dice_stats  # across all rolls on this table
  attr_reader   :total_rolls # across all shooters

  delegate :players, :dice_tray, to: :table

  ROLL_HISTORY_LENGTH = 100

  def initialize(table, roll_history_length=ROLL_HISTORY_LENGTH)
    @table = table
    no_shooter
    init_stats(roll_history_length)
    setup_callbacks
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
      @start_point_roll_count = nil
    end
    player
  end

  def done
    return_dice
    @player = nil
  end

  def roll
    raise "no roll. need a player to take the dice" if dice.nil?
    dice.roll.tap { |value|
      @roll_history << value
      player.dice_stats.update
      player.shooter_stats.rolls.incr
      @total_rolls += 1
    }
  end

  def num_rolls
    #
    # current roll number for the active shooter.  Resets to zero
    # when the shooter is 'set'
    #
    dice.try(:num_rolls) || 0
  end

  def num_rolls_after_first_point
    @start_point_roll_count.nil? ? 0 : num_rolls - @start_point_roll_count
  end

  def last_rolls(n=1)
    l = @roll_history.last(n)
    n > 1 ? l : l.first
  end

  def return_dice
    raise "no shooter" if dice.nil?
    dice_tray.return_dice(dice)
    no_shooter
  end

  def reset
    return_dice if dice.present?
    reset_stats
  end

  def reset_stats
    dice_stats.reset
    @roll_history.clear
    @total_rolls = 0
  end

  def no_shooter
    @player = nil
    @dice = nil
  end

  private
  
  def init_stats(roll_history_length)
    @dice_stats = RollStats.new("dice", table: table)
    @dice_stats.add_stats
    @roll_history = RingBuffer.new(roll_history_length)
    @total_rolls = 0
    @start_point_roll_count = nil
  end

  def setup_callbacks
    table.table_state.on(:seven_out) do
      player.shooter_stats.commit
      done
    end

    table.table_state.on(:point_made) do
      player.shooter_stats.points.incr
    end

    table.table_state.on(:point_established) do
      @start_point_roll_count ||= num_rolls
    end
  end
end
