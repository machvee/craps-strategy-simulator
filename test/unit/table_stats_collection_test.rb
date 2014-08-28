class TestStatsCollection < TableStatsCollection
end

class TableStatsCollectionTest < Test::Unit::TestCase
  def setup
    table = mock()
    @c = TestStatsCollection.new(table)
  end
end
