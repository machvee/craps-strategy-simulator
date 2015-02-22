require 'rails_helper'

describe Stickman do
  before(:each) do 
    @player_name = 'highroller_dave'
    @num_rolls = 18
    @player = double("player", name: @player_name)

    @table_state = double("table_state",
      off?: true,
      point_made?: false,
      seven_out?: false,
      winner_seven?: false,
      yo_eleven?: true
    )
    @table = double("table", table_state: @table_state)
    @shooter = double("shooter", player: @player, num_rolls: @num_rolls)
    @dice_tray = double("dice_tray", randomize: nil)

    @stickman = Stickman.new(
      @table,
      shooter: @shooter,
      dice_tray: @dice_tray
    )
  end

  it "should have an accessible dice_tray" do
    expect(@stickman.dice_tray).not_to be nil
  end

  it "should have an accessible shooter" do
    expect(@stickman.shooter).not_to be nil
  end

  it "should allow a shooter to take the dice" do
    @dice = double("dice", take_dice: nil, watch_always: nil)

    allow(@dice_tray).to receive(:take_dice).and_return(@dice)
    expect(@stickman.take_dice).to eq(@dice)
    expect(@dice).to have_received(:watch_always).with(:dice_rolled)
  end

  it "should give shooter dice and let him roll" do
    allow(@shooter).to receive(:set)
    allow(@shooter).to receive(:roll)

    @stickman.give_shooter_dice_and_let_him_roll

    expect(@shooter).to have_received(:set)
    expect(@shooter).to have_received(:roll)
  end

  it "should have watchers that fire when the dice that are out are rolled" do
    @dice = CrapsDice.new(DiceTray::NUM_SHOOTER_DIE, DefaultSeeder.new(9919988288))
    allow(@dice_tray).to receive(:take_dice).and_return(@dice)
    allow(@table).to receive(:status)

    @stickman.take_dice

    #
    # the roll of this dice should trigger a watcher in @stickman that calls 
    # status with a string announcing the roll to the table.  The first roll
    # of the dice with a fixed seed above is 5,6.
    #
    val = @dice.roll
    expect(@table).to have_received(:status).with("#@num_rolls: #@player_name rolls: #@dice #{val} -- YO!!")
  end

  it "should allow a reset" do
    allow(@dice_tray).to receive(:reset)
    allow(@shooter).to receive(:reset)

    @stickman.reset

    expect(@shooter).to have_received(:reset)
    expect(@dice_tray).to have_received(:reset)
  end
end
