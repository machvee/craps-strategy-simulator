class DiceTray
  #
  # a craps table dice tray.  The stickman owns it and offers it to a shooter who may take any 2 random
  # dice from it.  The dice are returned to this tray as well when the shooter would seven_out.
  #
  # options:
  #   :dice_seed        - pass in a seed value to guarantee a repeatable sequence
  #   :num_dice_in_tray - change the number of dice that are in the tray from the default
  #
  DEFAULT_NUM_TRAY_DIE=8
  NUM_SHOOTER_DIE=2

  attr_reader :num_dice
  attr_reader :tray
  attr_reader :seed

  def initialize(options={})
    @num_dice = options[:num_dice_in_tray]||DEFAULT_NUM_TRAY_DIE
    @seed = options[:dice_seed]||gen_random_seed
    set_tray_of_dice
  end

  def take_dice(offsets=nil)
    raise "dice are out" unless tray.count == @num_dice
    raise "take any #{NUM_SHOOTER_DIE} dice" if offsets.length != NUM_SHOOTER_DIE unless offsets.nil?
    take_a_pair_of_dice_or_extact_die_at_specific_offsets(offsets)
  end

  def randomize
    #
    # roll dice around and change around offsets
    #
    2.times do
      tray.shuffle!
      3.times {tray.roll}
    end
    self
  end

  def return_dice(dice)
    tray.join(dice)
    self
  end

  def reset
    set_tray_of_dice
    self
  end

  def dice_value_range
    @dvr ||= begin
      CrapsDice.new(NUM_SHOOTER_DIE).value_range
    end
  end

  def inspect
    @tray.inspect
  end

  private 

  def take_a_pair_of_dice_or_extact_die_at_specific_offsets(offsets)
    offsets.nil? ? tray.extract(NUM_SHOOTER_DIE) : tray.extract(offsets)
  end

  def set_tray_of_dice
    @tray = CrapsDice.new(num_dice, DefaultSeeder.new(seed))
  end

  def gen_random_seed
    Random.new_seed
  end

end
