//
// Created by Teltonika
//

#ifndef SIM_SW_H
#define SIM_SW_H
struct rules{
	int switch_signal;// = uci:get("sim_switch","rules","switchsignal_sim1")
	int switch_data; //= uci:get("sim_switch","rules","switchdata_sim1")
	char period[32];//= uci:get("sim_switch","rules","period_sim1")
	int start_day; //= tonumber(uci:get("sim_switch", "rules", "start_day_sim1"))
	int start_hour; //= tonumber(uci:get("sim_switch", "rules", "start_hour_sim1"))
	int start_weekday; //= tonumber(uci:get("sim_switch", "rules", "start_weekday_sim1"))
	int data_limit; // = tonumber(uci:get("sim_switch","rules","data_sim1")) or 0
	int min_signal; //= tonumber(uci:get("sim_switch","rules","signal_sim1"))
	int switch_roaming; //= uci:get("sim_switch","rules","switchroaming_sim1")
	int on_denied; //= uci:get("sim_switch","rules","ondenied1") or 0
	int switch_no_network; //= uci:get("sim_switch","rules","switchnonetwork_sim1")
	int switch_fails; //= uci:get("sim_switch","rules","switchfails_sim1")
	int switch_timeout; //=  uci:get("sim_switch","rules","switchtimeout_sim1")
	int initial; //= tonumber(uci:get("sim_switch","rules","initial_sim1")) or 1
	int subsequent; //= tonumber(uci:get("sim_switch","rules","subsequent_sim1")) or 1
	int switch_sms; // = uci:get("sim_switch","rules","switchsms_sim1")
	char period_sms[32]; //= uci:get("sim_switch","rules","period_sms_sim1")
	int sms_day; //= uci:get("sim_switch", "rules", "sms_day_sim1")
	int sms_hour; //= uci:get("sim_switch", "rules", "sms_hour_sim1")
	int sms_weekday; //= uci:get("sim_switch", "rules", "sms_weekday_sim1")
	int sms_limit; //= tonumber(uci:get("sim_switch","rules","sms_sim1")) or 0
	char check_method[32]; //= uci:get("sim_switch", "rules", "check_method_sim1")
	char icmp_hosts[32]; //= uci:get("sim_switch", "rules", "icmp_hosts_sim1") or "8.8.8.8"
	int timeout; //= tonumber(uci:get("sim_switch", "rules", "timeout_sim1"))
	int health_fail_retries; //= tonumber(uci:get("sim_switch", "rules", "health_fail_retries_sim1"))
};
#define debug_syslog(logLevel, fmt, ...) do { if (debug) syslog(logLevel, fmt, ##__VA_ARGS__); } while (0)
int debug=1;

int set_bridge();
int set_passthrough_bridge();
int disable_bridge();
int disable_passthrough_bridge();

int editFile(char *fle, char *str, int action);
int get_wan(char *ret);

int check_sim();
int switch_sim(char *status, char *ignore_config, char *ignore_sleep);
int restart_services();
int lock_unlock (char *action);
int get_data_from_mdc_db(struct rules *sim_rules, int *rx, int *tx);
int get_data_from_sms_db(struct rules *sim_rules);
int switch_config();
int set_config();
#endif
