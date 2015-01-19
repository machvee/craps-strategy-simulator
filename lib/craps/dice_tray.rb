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
  attr_reader :metadice # a static pair of dice never rolled, but useful in getting meta-info about 2 dice

  def initialize(options={})
    @num_dice = options[:num_dice_in_tray]||DEFAULT_NUM_TRAY_DIE
    @seed = options[:dice_seed]||gen_random_seed
    set_tray_of_dice
    @metadice = CrapsDice.new(NUM_SHOOTER_DIE)
  end

  def take_dice(offsets=nil)
    raise "dice are out" unless tray.count == @num_dice
    raise "take any #{NUM_SHOOTER_DIE} dice" if offsets.length != NUM_SHOOTER_DIE unless offsets.nil?
    dice = offsets.nil? ? tray.extract(NUM_SHOOTER_DIE) : tray.extract(offsets)
    dice
  end

  def return_dice(dice)
    tray.join(dice)
  end

  def reset
    set_tray_of_dice
  end

  def dice_value_range
    @dvr ||= metadice.value_range
  end

  private 

  def set_tray_of_dice
    @tray = CrapsDice.new(num_dice, DefaultSeeder.new(seed))
  end

  def gen_random_seed
    Random.new_seed
  end

end
