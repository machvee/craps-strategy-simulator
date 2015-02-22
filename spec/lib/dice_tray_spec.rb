require 'rails_helper'


describe DiceTray do
  before(:each) do 
  end

  it "should create a tray of dice of specified length" do
    num_die = 4
    @dice_tray = DiceTray.new(num_dice_in_tray: num_die)
    expect(@dice_tray.num_dice).to equal(num_die)
  end

  it "should create a tray of dice of default 8 die" do
    @dice_tray = DiceTray.new
    expect(@dice_tray.num_dice).to equal(8)
  end

  it "should allow me to take 2, rollable dice" do
    @dice_tray = DiceTray.new
    dice = @dice_tray.take_dice
    expect(dice.count).to equal(2)
    expect(@dice_tray.dice_value_range.include?(dice.roll)).to be true
  end

  it "should be resettable and restart its behaviour identical to its behaviour at initiation" do
    @dice_tray = DiceTray.new
    dice = @dice_tray.take_dice
    values = []
    100.times {values << dice.roll}
    @dice_tray.return_dice(dice)
    dice = @dice_tray.take_dice
    100.times {values << dice.roll}

    @dice_tray.reset
    dice = @dice_tray.take_dice
    new_values = []
    100.times {new_values << dice.roll}
    @dice_tray.return_dice(dice)
    dice = @dice_tray.take_dice
    100.times {new_values << dice.roll}

    expect(values.length).to equal(200)
    expect(new_values.length).to equal(200)

    expect(values).to match_array(new_values)
  end

  it "should allow me to seed the dice_tray for repeatability of roll sequence" do
    seed = 999988777654
    @dice_tray1 = DiceTray.new(dice_seed: seed)
    @dice_tray2 = DiceTray.new(dice_seed: seed)
    expect(@dice_tray1.seed).to equal(seed)
    expect(@dice_tray2.seed).to equal(seed)
    dice1 = @dice_tray1.take_dice
    values1 = []
    100.times {values1 << dice1.roll}
    dice2 = @dice_tray2.take_dice
    values2 = []
    100.times {values2 << dice2.roll}
    v2iter = values2.each
    values1.each { |v1| expect(v1).to equal(v2iter.next)}
  end

  it "should allow the tray of dice to be randomized by position and die value" do
    seed = 1979488777654
    @dice_tray1 = DiceTray.new(dice_seed: seed)
    @dice_tray2 = DiceTray.new(dice_seed: seed)
    expect(@dice_tray1.seed).to equal(seed)
    expect(@dice_tray2.seed).to equal(seed)
    dice1 = @dice_tray1.take_dice
    values1 = []
    329.times {values1 << dice1.roll}

    values2 = []
    @dice_tray2.randomize
    dice2 = @dice_tray2.take_dice
    329.times {values2 << dice2.roll}
    expect(values1.sort).not_to equal(values2.sort)
  end
end
