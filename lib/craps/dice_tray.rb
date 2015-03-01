class DiceTray
  #
  # a tray of 8 craps dice.  A shooter may take any 2 dice from it.
  #
  DEFAULT_NUM_TRAY_DIE=8
  NUM_SHOOTER_DIE=2

  attr_reader :tray
  attr_reader :num_dice
  attr_reader :seed

  def initialize(options={})
    @num_dice = options[:num_dice_in_tray]||DEFAULT_NUM_TRAY_DIE
    @seed = options[:seed]||gen_random_seed
    set_tray_of_dice
  end

  def take_dice(offsets=nil)
    raise "dice are out" unless tray.count == @num_dice
    if offsets.nil?
      randomize
      tray.extract(NUM_SHOOTER_DIE)
    else
      raise "take any #{NUM_SHOOTER_DIE} dice" if offsets.length != NUM_SHOOTER_DIE
      tray.extract(offsets)
    end
  end

  def reset
    set_tray_of_dice
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

  def set_tray_of_dice
    @tray = CrapsDice.new(num_dice, DefaultSeeder.new(seed))
  end

  def gen_random_seed
    Random.new_seed
  end

  def return_dice(dice)
    tray.join(dice)
  end

  def dice_value_range
    @dvr ||= begin
      CrapsDice.new(NUM_SHOOTER_DIE).value_range
    end
  end
end
