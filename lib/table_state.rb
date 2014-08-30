class TableState
  attr_reader :on_off #  true table on, false table off
  attr_reader :point  # 4,5,6,8,9 or 10
  attr_reader :table  # table we belong to

  def initializer(table)
    @table = table
    table_off
  end

  def update
    if point_established?
      table_on(table.dice.value)
    elsif point_made? || seven_out?
      table_off
    end
  end

  def table_off
    @on_off = false
    @point = nil
  end

  def table_on(point)
    @on_off = true
    @point = point
    return
  end

  def point_established?
    off? && table.dice.points?
  end

  def point_made?
    on? && (table.dice.value == point)
  end

  def seven_out?
    on? && table.dice.seven?
  end

  def on?
    on_off
  end

  def off?
    on_off
  end
end
