require 'test_helper'

class OccurrenceTableStatsCollectionTest < ActiveSupport::TestCase
  class TestOccurrenceStatsCollection < OccurrenceTableStatsCollection
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
    c = TestOccurrenceStatsCollection.new('test', table)
    c.add(OccurrenceStat.new('alpha') {table.is_alpha == 100})
    c.add(OccurrenceStat.new('beta') {table.is_beta == 200})
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

end
