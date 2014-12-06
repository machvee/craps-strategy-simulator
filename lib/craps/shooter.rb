class Shooter
  attr_reader   :table
  attr_reader   :player
  attr_reader   :last_shooter
  attr_accessor :dice
  attr_reader   :roll_stats # across all rolls on this table

  delegate :players, :dice_tray, to: :table

  ROLL_HISTORY_LENGTH = 100

  def initialize(table, roll_history_length=ROLL_HISTORY_LENGTH)
    @table = table
    no_shooter
    @roll_stats = RollStats.new("dice", table: table)
    @roll_stats.add_stats
    @roll_history = RingBuffer.new(roll_history_length)

    setup_callback_every_time_the_table_goes_seven_out
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
    raise "no roll. need a player to take the dice" if dice.nil?
    dice.roll.tap { |value|
      @roll_history << value
      player.roll_stats.update
    }
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
    roll_stats.reset
    @roll_history.clear
  end

  def no_shooter
    @player = nil
    @dice = nil
  end

  def total_rolls
    roll_stats.stats.first.count
  end

  private
  
  def setup_callback_every_time_the_table_goes_seven_out
    table.table_state.on(:seven_out) do |tbl|
      done
    end
  end
end
