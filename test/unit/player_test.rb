require 'test_helper'

class PlayerTest < ActiveSupport::TestCase
  def setup
    @table = mock('table')
    @amount = 1000
  end

  def test_instantiate_player
    new_player
    assert @player.present?
  end

  def test_join_table
    @table.expects(:new_player).with('dave', @amount).once
    Player.join_table(@table, 'dave', @amount)
  end

  def test_make_valid_bet
    new_player
    @amount = 10
    player_bet = mock('player_bet')
    bet_box = mock('bet_box')
    bet_box.expects(:new_player_bet).with(@player, @amount).returns(player_bet)
    craps_bet = mock('craps_bet')
    craps_bet.expects(:scale_bet).with(10).returns(10)
    bet_box.expects(:craps_bet).returns(craps_bet).at_least_once
    @table.expects(:find_bet_box).once.with('pass_line', 2).returns(bet_box)
    @player.make_bet('pass_line', @amount, 2)
  end

  def new_player
    bet_stats = mock('bet_stats')
    bet_stats.expects(:new_child_instance).once
    shooter = mock('shooter')
    dice_stats = mock('dice_stats')
    shooter.expects(:dice_stats).once.returns(dice_stats)
    dice_stats.expects(:new_child_instance).once
    @table.expects(:player_bet_stats).returns(bet_stats)
    @table.expects(:config).returns(mock('config', min_bet: 10))
    @table.expects(:shooter).once.returns(shooter)
    @player = Player.new('dave', @table, @amount)
  end

end
