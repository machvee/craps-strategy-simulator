require 'test_helper'


class TableStatsCollectionTest < ActiveSupport::TestCase
  class TestStatsCollection < TableStatsCollection
  end

  def setup
    @table, @c = new_collection

    @total_alpha = 187
    @total_beta = 213
    @total_combined=141
    @total_neither=16
  end

  def assert_start_at_zero
    assert_equal 0, @c.alpha.total
    assert_equal 0, @c.beta.total
  end

  def test_updates_in_children_roll_up_to_parent
    @c2 = @c.new_child_instance('another alpha_beta 1')
    @c3 = @c.new_child_instance('another alpha_beta 2')
    assert_equal nil, @c.parent_stats
    assert_equal @c, @c2.parent_stats
    assert_equal @c, @c3.parent_stats

    assert_equal 0, @c2.alpha.total
    assert_equal 0, @c2.beta.total
    assert_equal 0, @c3.alpha.total
    assert_equal 0, @c3.beta.total

    runit(@table, @c2, @c3)

    assert_equal (@total_alpha+@total_combined)*2, @c.alpha.total
    assert_equal (@total_beta+@total_combined)*2, @c.beta.total
    assert_equal @total_alpha+@total_combined, @c2.alpha.total
    assert_equal @total_beta+@total_combined, @c3.beta.total
  end

  def test_convenience_methods
    runit(@table, @c)
    assert_equal @total_alpha+@total_combined, @c.alpha.total
    assert_equal @total_beta+@total_combined, @c.beta.total
  end

  def test_optional_counters_carry_to_children
    table_2 = mock()
    cp = TestStatsCollection.new('counts_test', table_2, [:gamma, :bravo, :zulu])
    cp.add(Stat.new('alpha'))
    cp.add(Stat.new('beta'))

    @alpha_gamma = 10
    @alpha_bravo = 3
    @beta_bravo = 7

    c2 = cp.new_child_instance('another counter alpha_beta 1')
    c3 = cp.new_child_instance('another counter alpha_beta 2')
    c4 = cp.new_child_instance('another counter alpha_beta 3')

    runit_counts(c2, c3, c4)

    total_alpha_gamma = (@total_alpha * @alpha_gamma)
    total_alpha_bravo = (@total_alpha * @alpha_bravo)
    total_beta_bravo =  (@total_beta * @beta_bravo)
    assert_equal total_alpha_gamma, c2.alpha.counters(:gamma)
    assert_equal total_alpha_bravo, c2.alpha.counters(:bravo)
    assert_equal total_beta_bravo, c2.beta.counters(:bravo)
    assert_equal total_alpha_gamma, c3.alpha.counters(:gamma)
    assert_equal total_alpha_bravo, c3.alpha.counters(:bravo)
    assert_equal total_beta_bravo, c3.beta.counters(:bravo)
    assert_equal total_alpha_gamma, c4.alpha.counters(:gamma)
    assert_equal total_alpha_bravo, c4.alpha.counters(:bravo)
    assert_equal total_beta_bravo, c4.beta.counters(:bravo)
    assert_equal total_alpha_gamma*3, cp.alpha.counters(:gamma)
    assert_equal total_alpha_bravo*3, cp.alpha.counters(:bravo)
    assert_equal total_beta_bravo*3, cp.beta.counters(:bravo)
    assert_equal 0, cp.alpha.counters(:zulu)
    assert_equal 0, cp.beta.counters(:zulu)
  end

  def test_won_by_name
    c = TestStatsCollection.new('test2', @table)
    c.add(Stat.new('alpha'))
    c.add(Stat.new('beta'))
    c.won('alpha')
    c.won('alpha')
    c.won('alpha')
    c.won('beta')
    c.won('beta')
    c.won('beta')
    c.incr('beta')
    c.lost('alpha')
    c.lost('beta')
    assert_equal 3, c.alpha.total
    assert_equal 4, c.beta.total
    assert_equal 1, c.stat_by_name('alpha').total_lost
    assert_equal 1, c.stat_by_name('beta').total_lost
  end

  def test_reset
    runit(@table, @c)
    assert_equal @total_alpha+@total_combined, @c.alpha.total
    assert_equal @total_beta+@total_combined, @c.beta.total
    @c.reset
    assert_equal 0, @c.alpha.total
    assert_equal 0, @c.beta.total
  end

  def test_each
    runit(@table, @c)
    assert_equal @total_alpha+@total_combined, @c.alpha.total
    assert_equal @total_beta+@total_combined, @c.beta.total
    exp = %w{alpha beta}.each
    @c.each { |stat| assert_equal exp.next, stat.name }
  end

  def new_collection
    table = mock()
    c = TestStatsCollection.new('test', table)
    c.add(Stat.new('alpha') {table.is_alpha == 100})
    c.add(Stat.new('beta') {table.is_beta == 200})
    [table, c]
  end

  def t_expects(t, a, b)
    t.expects(:is_alpha).at_least_once.returns(a)
    t.expects(:is_beta).at_least_once.returns(b)
  end

  def runit(table, *collections)
    t_expects(table, 100, 100)
    collections.each { |c| @total_alpha.times {c.update} }

    t_expects(table, 200, 200)
    collections.each { |c| @total_beta.times {c.update} }

    t_expects(table, 100, 200)
    collections.each { |c| @total_combined.times {c.update} }

    t_expects(table, 0, 0)
    collections.each { |c| @total_neither.times {@c.update} }
  end

  def runit_counts(*collections)
    collections.each { |c| @total_alpha.times {c.won('alpha', gamma: @alpha_gamma, bravo: @alpha_bravo)} }
    collections.each { |c| @total_beta.times {c.lost('beta', bravo: @beta_bravo)} }
  end
end
