require_relative "FTM_ini"

File.basename(__FILE__) =~ /(\d+)\.rb$/
@sot.test_nr = $1

###############################################################################

@date_limit = @sot.var :date_limit

_date_main_start    = @date_limit - 20*24*3600
_date_main_end      = @date_limit - 10*24*3600

_tokens_per_eth = 10_000

###############################################################################

@sl.h1 'Main day one'

jump_to(_date_main_start + 1, 'presale start + 0')

###

@sot.txt 'Modify tokens per ETH (not during presale) and whitelisting (not on first day)'
@sot.own :update_tokens_per_eth, 15_000
@sot.own :open_migration_phase
@sot.own :add_to_whitelist, @a[13]
@sot.exp :tokens_per_eth, 10_000, 0
@sot.exp :whitelist, @a[13], false
@sot.exp :is_main_first_day, true
@sot.exp :is_migration_phase_open, false
@sot.do

###

@sot.txt 'Big contribution (over limit)'
eth = 10_000
@sot.snd @k[1], eth
@sot.exp :balance_of, @a[1], nil, 6_000 * _tokens_per_eth * @E18
@sot.exp :get_balance, @a[1], nil, -6_000 * @E18
@sot.do

###

@sot.txt 'Big contribution (over limit)'
eth = 10_000
@sot.snd @k[2], 5900
@sot.snd @k[2], 99.6
@sot.snd @k[2], 1
@sot.exp :balance_of, @a[2], nil, 6_000 * _tokens_per_eth * @E18
@sot.exp :get_balance, @a[2], nil, -6_000 * @E18
@sot.do

###

@sot.txt 'Small contribution - fails because not whitelisting'
@sot.snd @k[13], 100
@sot.exp :balance_of, @a[13], nil, 0
@sot.exp :get_balance, @a[13], nil, 0
@sot.do

###############################################################################

@sl.h1 'Main after day one'

jump_to(_date_main_end - 1, 'presale after day one')

###

@sot.txt 'Modify tokens per ETH (still not) and whitelisting (now ok)'
@sot.own :update_tokens_per_eth, 15_000
@sot.own :add_to_whitelist, @a[14]
@sot.exp :tokens_per_eth, 10_000, 0
@sot.exp :whitelist, @a[14], true
@sot.exp :is_main_first_day, false
@sot.do

###

@sot.txt 'A big contribution from 8'
eth = 10_000
@sot.snd @k[8], eth
@sot.exp :balance_of, @a[8], nil, eth * _tokens_per_eth * @E18
@sot.exp :get_balance, @a[8], nil, -eth * @E18

@sot.exp :tokens_minted, 170_000_000 * @E18
@sot.exp :tokens_main, 220_000_000 * @E18
@sot.exp :tokens_issued_total, 390_000_000 * @E18
@sot.exp :available_to_mint, 230_000_000 * @E18
@sot.exp :total_eth_contributed, 22_000 * @E18

@sot.do

###############################################################################

@sl.h1 'After main sale'

jump_to(_date_main_end + 1, 'presale after day one')

###

@sot.txt 'No contribution possible any more'
eth = 1
@sot.snd @k[10], eth
@sot.exp :balance_of, @a[10], nil, 0
@sot.exp :get_balance, @a[10], nil, 0
@sot.do

###

@sot.txt 'Transfers not yet possible'
@sot.add :transfer, @k[7], @a[17], 1_000_000*@E18
@sot.exp :balance_of, @a[7], nil, 0
@sot.exp :balance_of, @a[17], nil, 0
@sot.do

###

@sot.txt 'Owner makes transferable - transfers ok'
@sot.own :make_tradeable
@sot.add :transfer, @k[1], @a[15], 1_000_000*@E18
@sot.exp :tokens_tradeable, true
@sot.exp :balance_of, @a[1], nil, -1_000_000*@E18
@sot.exp :balance_of, @a[15], nil, 1_000_000*@E18
@sot.do

###



###############################################################################

@sot.dump
output_pp @sot.get_state(true), "state_#{@sot.test_nr}.txt"
