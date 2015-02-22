class Table

  attr_reader    :name
  attr_reader    :bet_boxes
  attr_reader    :tracking_bet_stats   # based on outcome of tracking_bets
  attr_reader    :player_bet_stats     # rolled up from bet_stats on player bets
  attr_reader    :table_state
  attr_reader    :table_heat
  attr_reader    :config
  attr_reader    :stickman
  attr_accessor  :dice
  attr_reader    :tracking_strategy    # makes the tracking bets
  attr_reader    :tracking_player
  attr_reader    :players
  attr_reader    :player_strategies    # bet making strategies tied to players
  attr_reader    :house   # house Account
  attr_reader    :wagers  # Account holding all active table bets
  attr_accessor  :quiet_table # not verbose about all actions
  attr_accessor  :pause_option # stop after each roll and prompt stdin if true

  delegate :on?, :off?, :last_roll,                     to: :table_state
  delegate :is_hot?, :is_good?, :is_choppy?, :is_cold?, to: :table_heat
  delegate :dice, to: :stickman

  delegate :total_rolls,        to: :shooter
  delegate :min_bet, :max_bet,  to: :config

  DEFAULT_OPTIONS = {
    config:                    TableConfig.new,
    die_seeder:                nil,
    quiet_table:               false,
    table_heat_history_points: 15
  }

  BET_STATS_HEADERS = {
    count:         'total',
    won:           'won',
    win_streak:    'win streak',
    lost:          'lost',
    losing_streak: 'lost streak'
  }


  def initialize(name="craps table", options = {})
    opts = DEFAULT_OPTIONS.merge(options)
    @name = name
    @config = opts[:config]

    @table_state = TableState.new(self, opts[:table_heat_history_points])
    table_state.table_off

    @stickman = Stickman.new(
      self,
      dice_tray: DiceTray.new(table_options),
      shooter: Shooter.new(self)
    )

    setup_watcher_for_on_seven_out

    #
    # house is the houses money Account
    # wagers is waged bets on the table, neither belongs to player or house
    #
    @house = Account.new('house', config.house_bank)
    @wagers = Account.new('current wagers', 0)

    @quiet_table = opts[:quiet_table]

    @player_bet_stats = CountersStatsCollection.new(
                          "player bet results",
                          counter_names: [:made, :won, :lost]
                        )
    @players = []
    @player_strategies = []

    @tracking_player = TrackingPlayer.new(self)
    @tracking_bet_stats = tracking_player.stats.bet_stats

    create_bet_boxes

    @tracking_strategy = TrackingPlayer::TRACKING_STRATEGY.new(tracking_player)
    tracking_strategy.set

  end

  def set_player_strategy(strategy)
    strategy.set
    @player_strategies << strategy
  end

  def retire_player_strategy(strategy)
    strategy.retire
    player_strategies.delete(strategy)
  end

  def reset_player_strategies
    player_strategies.each {|strategy| strategy.reset}
  end

  def max_odds(number)
    config.max_odds(number)
  end

  def play(quiet_option=quiet_table)
    #
    # players make automatic strategy bets,
    # one roll of the dice, and the outcomes are
    # tallied.
    #
    quietly?(quiet_option) do
      # 1. players make automatic bets based on Strategy
      # 2. shooter rolls dice and table state is updated
      #
      player_strategies.each {|strategy| strategy.make_bets}
      raise "place your bets" unless at_least_one_bet_made?
      roll
    end
    optionally_pause
    return
  end

  def roll
    tracking_strategy.make_bets
    shooter_rolls
    settle_bets
    YOU ARE HERE ^^ settle_bets should be done with WIN/LOSE/MORPH watchers on table_state.  table_state needs 'dice value rolled' watchers
    # table_state.update >>>> no longer needed because we have dice watchers in table_state now
  end

  def new_player(name, start_amount, bet_unit=nil)
    Player.new(name, self, start_amount, bet_unit).tap do |p|
      @players << p
    end
  end

  def find_player(name)
    players.find {|p| p.name == name}
  end

  def players_ready?
    #
    # return true if one or more @players are at the table and want to bet, else false
    #
    @players.each do |player|
      if player.out?
        player.leave_table
        players.delete(player)
      end
    end
    return !players.empty?
  end

  def settle_bets
    #
    # settle the bets, then morph (move) any come out or pass line bets
    # to their numbered bet version if a point was established
    #
    bet_boxes.each { |bet_box| bet_box.settle_player_bets }
    bet_boxes.each { |bet_box| bet_box.morph_any_bets }
  end

  def at_least_one_bet_made?
    players.any? {|p| p.bets.length > 0}
  end

  def reset
    #
    # this is destructive to the current state of the table and accounts.
    # use this call to set the table and player state back to the point
    # where the players have just joined and no rolls or bets have been
    # yet made.   The table dice will be seeded identically so you
    # can have players use a different strategy against the same roll
    # outcomes as before.
    tracking_bet_stats.reset
    tracking_strategy.reset
    player_bet_stats.reset
    reset_player_strategies
    table_state.reset
    house.reset
    wagers.reset
    bet_boxes.each {|bb| bb.reset}
    players.each {|p| p.reset}
    stickman.reset
    return
  end

  def shooter_rolls
    stickman.give_shooter_dice_and_let_him_roll
  end

  def status(str, color=:white)
    puts(str.colorize(color)) unless quiet_table
  end


  def find_bet_box(bet_short_name, number=nil)
    bet_boxes.find {|bet| bet.short_name == bet_short_name && bet.number == number} ||
      raise("#{bet_short_name}%s isn't a valid bet" % (number.nil? ? '' : " #{number}"))
  end

  def inspect
    summary
  end

  def summary
    [
     "%s [%s (%4.2f)]" % [name||"table", table_state.heat_index_in_words, table_state.heat_index],
     on? ? "ON (point is #{table_state.point})" : "OFF" ,
     "rolls: #{total_rolls}",
     "#{house}",
    ].join("\n")
  end

  def stats
    summary
    puts '-'*100
    tracking_bet_stats.print(BET_STATS_HEADERS)
    puts '-'*100
    stickman.shooter.roll_stats.print
    puts "\n"
  end

  private

  def setup_watcher_for_on_seven_out
    table_state.watch_for(:seven_out, :reset_player_strategies) do |cb_name, t_state|
      reset_player_strategies
    end
  end

  def optionally_pause
    # this allows a viewer in console to read the status for each roll
    # pause for newline if table.pause_option is true
    # if anything besides newline is typed, pause_option is set to false
    return unless pause_option
    v = $stdin.readline
    @pause_option = v.strip.length == 0
  end

  def create_bet_boxes
    @bet_boxes = []
    BetBox::NO_NUMBER_BETS.each do |bet_class|
      craps_bet = bet_class.new(self)
      @bet_boxes << BetBox.new(self, craps_bet)
    end

    BetBox::NUMBER_BETS.each do |bet_class|
      craps_bets = bet_class.gen_number_bets(self)
      @bet_boxes += craps_bets.map {|b| BetBox.new(self, b)}
    end
  end

  def point_outcomes
    tracking_bet_stats.pass_line_point.count # total won and lost
  end

  def quietly?(option)
    save_state = quiet_table
    @quiet_table = option
    yield
    @quiet_table = save_state
    return
  end
end
