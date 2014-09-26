class BaseStrategy
  attr_reader :table
  attr_reader :player

  delegate :table_state, to: :table

  def initialize(player)
    @player = player
    @table = player.table
  end

  def make_bets
    # override this with logic that makes bets based on player state, bet history
    # and table state
  end

  private

  def pass_line_bet_with_full_odds
    player.pass_line if table_state.off?
    player.pass_odds if table_state.on? && player.has_bet?('pass_line_point')
  end

  def hardways_bet_on_the_point(amount)
    player.hardways(table_state.point, amount) if table_state.on? &&
      CrapsDice::HARDS.include?(table_state.point)
  end

  def all_the_hardways(amount=nil)
    CrapsDice::HARDS.each do |n|
      player.hardways(n, amount)
    end
  end

  def six_and_eight
    [6,8].each do |n|
      player.place(n) unless table_state.point?(n)
    end if table_state.on?
  end

  def inside
    CrapsDice::INSIDE.each do |n|
      player.place(n) unless table_state.point?(n)
    end if table_state.on?
  end

  def across
    CrapsDice::POINTS.each do |n|
      player.place(n) unless table_state.point?(n)
    end if table_state.on?
  end

  def all_across
    CrapsDice::POINTS.each do |n|
      player.place(n)
    end if table_state.on?
  end

  def come_out_bet_with_full_odds
    if table_state.on?
      player.come_out 
      CrapsDice::POINTS.each do |number|
        player.come_odds(number) if player.has_bet?('come', number)
      end
    end
  end

  def all_prop_bets(amount = nil)
    Table::PROPOSITION_BETS.each do |bet|
      player.send(bet.short_name, amount)
    end
  end

  def field
    player.field
  end

end
