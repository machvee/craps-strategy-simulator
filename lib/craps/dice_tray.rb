class DiceTray
  #
  # a craps table dice tray.  A shooter may take any 2 dice from it.  The dice know
  # which tray they came from so when rolled, can automatically update the RollStats
  # kept here.  The dice know how to be returned to this tray as well when the shooter
  # seven_out's
  #
  DEFAULT_NUM_TRAY_DIE=8
  NUM_SHOOTER_DIE=2

  attr_reader :tray
  attr_reader :metadice
  attr_reader :num_dice

  def initialize(table, die_seeder, num_dice_in_tray=DEFAULT_NUM_TRAY_DIE)
    @tray = CrapsDice.new(@num_dice = num_dice_in_tray, die_seeder)
    @metadice = CrapsDice.new(NUM_SHOOTER_DIE)
  end

  def take_dice(offsets=nil)
    raise "dice are out" unless tray.count == @num_dice
    raise "take any #{NUM_SHOOTER_DIE} dice" if \
      offsets.length != NUM_SHOOTER_DIE unless offsets.nil?
    offsets.nil? ? tray.extract(NUM_SHOOTER_DIE) : tray.extract(offsets)
  end

  def return_dice(dice)
    tray.join(dice)
  end

  def dice_value_range
    @dvr ||= metadice.value_range
  end
end
