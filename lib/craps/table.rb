class Table

  attr_reader    :name
  attr_reader    :bet_boxes
  attr_reader    :tracking_bet_stats   # based on outcome of tracking_bets
  attr_reader    :player_bet_stats     # rolled up from bet_stats on player bets
  attr_reader    :table_state
  attr_reader    :config
  attr_reader    :dice_tray
  attr_reader    :tracking_player
  attr_reader    :players
  attr_reader    :morph_bets
  attr_reader    :shooter # one of the above players or nil
  attr_reader    :house   # house Account
  attr_reader    :wagers  # Account holding all active table bets
  attr_accessor  :quiet_table # not verbose about all actions

  delegate :on?, :off?, :is_hot?, :is_good?, :is_choppy?, :is_cold?, to: :table_state

  delegate :dice,              to: :shooter
  delegate :min_bet, :max_bet, to: :config


  #
  # NO_NUMBER_BETS and NUMBER_BETS are all the types of bets on the table.  We
  # will create a BetBox for each NO_NUMBER_BET, and mulitple numbered BetBox for the
  # NUMBER_BETS.  MORPH_NUMBER_BETS are not directly 'makeable' by a player.  They are moved
  # (morphed) from a come out bet box to a 'point made' bet box automatically by the game
  #
  PROPOSITION_BETS = [
    AceDeuceBet,
    AcesBet,
    AnyCrapsBet,
    AnySevenBet,
    ElevenBet,
    TwelveBet
  ]

  NO_NUMBER_BETS = [
    *PROPOSITION_BETS,
    CeBet,
    ComeOutBet,
    FieldBet,
    PassLineBet
  ]

  MORPH_NUMBER_BETS = [
    ComeBet,
    PassLinePointBet
  ]

  NUMBER_BETS = [
    ComeOddsBet,
    HardwaysBet,
    PassOddsBet,
    PlaceBet,
    *MORPH_NUMBER_BETS
  ]

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


  def initialize(name="craps table", options = DEFAULT_OPTIONS)
    @name = name
    @config = options[:config]

    @table_state = TableState.new(self, options[:table_heat_history_points])
    table_state.table_off

    #
    # house is the houses money Account
    # wagers is waged bets on the table, neither belongs to player or house
    #
    @house = Account.new('house', config.house_bank)
    @wagers = Account.new('current wagers', 0)

    @quiet_table = options[:quiet_table]

    @dice_tray = DiceTray.new(self, options[:die_seeder])

    @player_bet_stats = CountersStatsCollection.new(
                          "player bet results",
                          counter_names: [:made, :won, :lost]
                        )
    @players = []
    @morph_bets = []
    @tracking_player = TrackingPlayer.new(self)
    @tracking_bet_stats = tracking_player.stats.bet_stats

    create_bet_boxes

    @shooter = Shooter.new(self)
  end

  def last_roll
    shooter.dice.value
  end

  def total_rolls
    shooter.total_rolls
  end

  def max_odds(number)
    config.max_odds(number)
  end
  def play(quiet_option=quiet_table)
    #
    # players make automatic strategy bets,
    # one roll of the dice, and the outcomes are
    # tallied
    #
    quietly?(quiet_option) do
      # 1. shooter rolls dice
      # 2. set table_state if on
      # 3. table pay players on winning bets, takes losing bets
      # 4. if 7-out, shooter will return_dice
      #
      raise "no players" unless players_ready?
      players_make_your_bets
      raise "place your bets" unless at_least_one_bet_made?
      roll_dice
    end
    return
  end

  def roll_dice
    shooter_rolls
    settle_bets
    morph_any_bets
    table_state.update
  end

  def players_make_your_bets

    tracking_player.play_strategy

    players.each do |p|
      p.play_strategy
    end
  end

  def shooter_turns(number_of_turns=1, quiet_option=quiet_table)
    number_of_turns.times do
      start_outs = tracking_bet_stats.pass_line_point.total_lost
      while tracking_bet_stats.pass_line_point.total_lost == start_outs do
        play(quiet_option) 
      end
    end
  end

  def play_points(number_of_points=1, quiet_option=quiet_table)
    #
    # roll as many times from as many shooters as it takes
    # to make and end number_of_points points
    #
    start_points = point_outcomes
    while (point_outcomes - start_points < number_of_points)
      play(quiet_option)
    end
    return
  end

  def new_player(name, start_amount, bet_unit=nil, strategy=nil)
    Player.new(name, self, start_amount, bet_unit, strategy||BasicStrategy).tap do |p|
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
    bet_boxes.each { |bet_box| bet_box.settle_player_bets }
  end

  def at_least_one_bet_made?
    players.any? {|p| p.bets.length > 0}
  end

  def reset
    players.each {|p| p.stats.reset}
    shooter.reset_stats
    tracking_bet_stats.reset
    player_bet_stats.reset
    table_state.reset
  end

  def shooter_rolls
    shooter.set
    shooter.roll
    announce_roll
  end

  def status(str)
    puts(str) unless quiet_table
  end

  def announce_roll
    status '%d: %s rolls: %2d %s %s' %
      [shooter.dice.num_rolls,
       shooter.player.name,
       last_roll,
       shooter.dice.inspect,
       table_state.stickman_calls_roll]
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
    shooter.roll_stats.print
    puts "\n"
  end

  private

  def create_bet_boxes
    @bet_boxes = []
    NO_NUMBER_BETS.each do |bet_class|
      craps_bet = bet_class.new(self)
      @bet_boxes << BetBox.new(self, craps_bet)
    end

    NUMBER_BETS.each do |bet_class|
      craps_bets = bet_class.gen_number_bets(self)
      @bet_boxes += craps_bets.map {|b| BetBox.new(self, b)}
    end
  end

  def point_outcomes
    tracking_bet_stats.pass_line_point.count # total won and lost
  end

  def morph_any_bets
    return if morph_bets.empty?
    morph_bets.each do |player_bet|
      player_bet.morph_bet
    end
    morph_bets.clear
  end

  def quietly?(option)
    save_state = quiet_table
    @quiet_table = option
    yield
    @quiet_table = save_state
    return
  end
end
