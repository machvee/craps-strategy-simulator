class Stickman
  #
  # the stickman controls the game.  He maintains the dice_try, picks the shooter,
  # give the shooter dice, calls the roll, and initiates the events that other
  # actors on the table are watching.
  #
  include Watchable

  attr_reader  :table
  attr_reader  :table_state
  attr_reader  :dice_tray
  attr_reader  :shooter # one of the above players or nil
  attr_reader  :dice  # these are the dice the shooter picked

  delegate :table_state, :status, to: :table

  def initialize(table, options={})
    @table = table
    @dice_tray = options[:dice_tray]
    @shooter = options[:shooter]
    set_stickman_watchers
  end

  def take_dice(offsets=nil)
    #
    # called by the Shooter. first the stickman will randomize the dice in the tray, then
    # the shooter chooses two dice at (random/specific) offsets
    # and sets the dice for the table and the shooter's run
    #
    dice_tray.randomize
    @dice = dice_tray.take_dice(offsets).tap do |d|
      set_dice_watchers(d)
    end
  end

  def reset
    dice_tray.reset
    shooter.reset
  end

  def give_shooter_dice_and_let_him_roll
    shooter.set
    shooter.roll
  end

  private

  def set_dice_watchers(dice)
    dice.watch_always(:dice_rolled) do |cb_name, rolled_dice|
      announce_roll(rolled_dice)
      check_watchers
    end
  end

  def announce_roll(dice)
    status '%d: %s rolls: %s %s' % [
      shooter.num_rolls,
      shooter.player.name,
      dice.inspect,
      call_it
    ]
  end

  def set_stickman_watchers
    watcher(:point_established) {|st| point_established?}
    watcher(:point_made)        {|st| point_made?}
    watcher(:seven_out)         {|st| seven_out?}
  end

  def call_it
    "%2d -- %s" % [last_roll, roll_in_words]
  end

  def roll_in_words
    if point_made?
      "WINNER!!  Pay the line."
    elsif seven_out?
      "OUT"
    elsif winner_seven?
      "FRONT LINE WINNER!!"
    elsif yo_eleven?
      "YO!!" 
    elsif crapped_out?
      "CRAP!!" 
    elsif point_established?
      "the point is #{last_roll}"
    elsif rolled?(5)
      "no field 5"
    elsif dice.hard?
      "hard"
    elsif dice.easy?
      "easy"
    end
  end

  def last_roll
    dice.value
  end

  def front_line_winner?(value=nil)
    table_state.off? && dice.winner? && match_roll?(value)
  end

  def point_made?
    table_state.point_made?
  end

  def point_established?
    table_state.point_established?
  end

  def seven_out?
    table_state.seven_out?
  end

  def crapped_out?
    table_state.off? && dice.craps?
  end

  def yo_eleven?
    front_line_winner?(11)
  end

  def winner_seven?
    front_line_winner?(7)
  end

  def rolled?(value)
    last_roll == value
  end
  
  def point?(value)
    point == value
  end

  def match_roll?(value)
    value.nil? || last_roll == value
  end

end
