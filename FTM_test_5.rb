require_relative "FTM_ini"

File.basename(__FILE__) =~ /(\d+)\.rb$/
@sot.test_nr = $1

###############################################################################

@sl.h1 'Migration / token exchange'

###

@sot.txt 'Token exchange - fails'
@sot.add :request_token_exchange, @k[2], 1_000_000 * @E18
@sot.exp :balance_of, @a[2], nil, 0
@sot.exp :tokens_issued_total, nil, 0
@sot.do

###

@sot.txt 'Open token exchange'
@sot.own :open_migration_phase
@sot.exp :is_migration_phase_open, true
@sot.do

###

@sot.txt 'Token exchange - ok'
@sot.add :request_token_exchange, @k[2], 1_000_000 * @E18
@sot.exp :balance_of, @a[2], nil, -1_000_000 * @E18
@sot.exp :tokens_issued_total, nil, -1_000_000 * @E18
@sot.do

###

@sot.txt 'Token exchange - too much'
@sot.add :request_token_exchange, @k[2], 100_000_000 * @E18
@sot.exp :balance_of, @a[2], nil, 0
@sot.exp :tokens_issued_total, nil, 0
@sot.do

###

@sot.txt 'Token exchange all - ok'
@sot.add :request_token_exchange_max, @k[2]
@sot.exp :balance_of, @a[2], nil, -69_000_000 * @E18
@sot.exp :tokens_issued_total, nil, -69_000_000 * @E18
@sot.do



###############################################################################

@sot.dump
output_pp @sot.get_state(true), "state_#{@sot.test_nr}.txt"
