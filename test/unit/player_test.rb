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
    @table.expects(:find_bet_box).once.with('pass_line', 2).returns(bet_box)
    start_r = @player.rail
    @player.make_bet('pass_line', @amount, 2)
    assert_equal @amount, @player.wagers
    assert_equal start_r - @amount, @player.rail
  end

  def new_player
    bet_stats = mock('bet_stats')
    bet_stats.expects(:new_child_instance).once
    shooter = mock('shooter')
    roll_stats = mock('roll_stats')
    shooter.expects(:roll_stats).once.returns(roll_stats)
    roll_stats.expects(:new_child_instance).once
    @table.expects(:player_bet_stats).returns(bet_stats)
    @table.expects(:shooter).once.returns(shooter)
    @player = Player.new('dave', @table, @amount)
  end

end
